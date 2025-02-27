WITH RecursiveTitleInfo AS (
    SELECT t.id, t.title, t.production_year, kt.kind AS kind, m.md5sum AS movie_md5
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN movie_info_idx m ON mi.id = m.info_type_id
    WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Release Date') 
    UNION ALL
    SELECT t.id, t.title, t.production_year, kt.kind AS kind, m.md5sum AS movie_md5
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE cn.country_code = 'USA'
)
SELECT rti.title, rti.production_year, rti.kind, ak.name AS actor_name, ak.md5sum AS actor_md5
FROM RecursiveTitleInfo rti
JOIN cast_info ci ON rti.id = ci.movie_id
JOIN aka_name ak ON ci.person_id = ak.person_id
WHERE rti.production_year > 2000 
AND rti.kind = 'movie'
ORDER BY rti.production_year DESC, rti.title;
