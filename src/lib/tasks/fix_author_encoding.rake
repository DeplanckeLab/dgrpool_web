desc '####################### fix_author_encoding: repair mojibake and normalize author names of studies (set APPLY=1 to save)'
task fix_author_encoding: :environment do

  # 1. Authors fetched from Crossref used to be wrongly re-encoded (UTF-8 bytes read as ISO-8859-1),
  #    e.g. "Barrón" -> "BarrÃ³n". The conversion is a byte-for-byte mapping, so it can be reversed exactly.
  #    Only revert when the string looks double-encoded and the result is valid UTF-8.
  # 2. Names are then normalized like new imports (CustomFetch.normalize_family / normalize_given):
  #    only all-caps names and bare initials are changed, mixed-case names (e.g. curated by hand) are kept.
  mojibake = /[Â-ô][\u0080-¿]/

  fix = lambda do |s|
    return s if !s.is_a?(String)
    prev = nil
    while s != prev and s.match?(mojibake)
      prev = s
      begin
        cand = s.encode(Encoding::ISO_8859_1).force_encoding(Encoding::UTF_8)
      rescue Encoding::UndefinedConversionError
        break
      end
      break unless cand.valid_encoding?
      s = cand
    end
    s
  end

  # authors_json may store non-ASCII chars as \uXXXX escapes (e.g. "JuliÃ¡n"),
  # invisible in the raw text: fix the parsed values instead
  deep_fix = lambda do |o|
    case o
    when String then fix.call(o)
    when Array then o.map { |e| deep_fix.call(e) }
    when Hash then o.transform_values { |e| deep_fix.call(e) }
    else o
    end
  end

  # orig: author before any fix; a: author after the encoding fix
  normalize = lambda do |orig, a|
    return a if !a.is_a?(Hash)
    a = a.dup
    a['lname'] = CustomFetch.normalize_family(a['lname']) if a['lname']
    if a['fname']
      a['fname'] = CustomFetch.normalize_given(a['fname'])
      # recompute initials only if the given name changed (encoding or format), otherwise keep them
      a['initials'] = CustomFetch.initials(a['fname']) if a['fname'] != orig['fname']
    end
    a
  end

  apply = ENV['APPLY'] == '1'
  n = 0
  Study.find_each do |study|
    changes = {}
    [:authors, :first_author].each do |f|
      new_v = fix.call(study[f])
      changes[f] = new_v if new_v != study[f]
    end

    parsed = nil
    fixed = nil
    if study.authors_json.present?
      begin
        parsed = JSON.parse(study.authors_json)
      rescue JSON::ParserError
        new_v = fix.call(study.authors_json)
        changes[:authors_json] = new_v if new_v != study.authors_json
      end
      if parsed.is_a?(Array)
        fixed = parsed.map { |a| normalize.call(a, deep_fix.call(a)) }
        if fixed != parsed
          changes[:authors_json] = fixed.to_json
          # keep authors / first_author consistent with the first author (as in StudiesController#update)
          fa = fixed.first
          if fa.is_a?(Hash) and fa['lname'] and fa['lname'] != (parsed.first || {})['lname']
            changes[:first_author] = fa['lname']
            changes[:authors] = fa['lname'] + ((fixed.size > 1) ? " et al." : '')
          end
        end
      end
    end
    changes.reject! { |f, v| v == study[f] }
    next if changes.empty?

    n += 1
    puts "Study #{study.id} (#{study.doi}):"
    changes.each do |f, v|
      if f == :authors_json and fixed
        # only show the author fields that change (the whole JSON is too long to read)
        parsed.zip(fixed).each do |old_a, new_a|
          next unless old_a.is_a?(Hash) and new_a.is_a?(Hash)
          old_a.each_key { |k| puts "  authors_json #{k}: #{old_a[k]} -> #{new_a[k]}" if old_a[k] != new_a[k] }
        end
      else
        puts "  #{f}: #{study[f]} -> #{v}"
      end
    end
    if apply
      study.update_columns(changes)
      # reindex phenotypes (fulltext search on study_authors)
      Sunspot.index(study.phenotypes.to_a)
    end
  end
  Sunspot.commit if apply and n > 0
  puts "#{n} studies #{apply ? 'fixed' : 'to fix (dry run, set APPLY=1 to save)'}"
end
