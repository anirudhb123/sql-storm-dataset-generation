SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.md5sum IN ('21dba63af6f529bce315f3982877aca0', '74acc3bb88ef1e3a334aabfe9631f476', '86b1cf121f6773b849a0c2259428f079', '92e08f3402715077a8fa32bd68374925', 'aa043484fa6ae167c3e39eb57531ebb6');