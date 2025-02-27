WITH movie_keyword_counts AS (
    SELECT mk.movie_id, COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movies_with_info AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 
           ARRAY_AGG(DISTINCT mt.kind) AS movie_types, 
           COALESCE(mkc.keyword_count, 0) AS keyword_count
    FROM title m
    LEFT JOIN kind_type mt ON m.kind_id = mt.id
    LEFT JOIN movie_keyword_counts mkc ON m.id = mkc.movie_id
    WHERE m.production_year >= 2000 AND m.production_year <= 2023
    GROUP BY m.id, m.title, m.production_year, mkc.keyword_count
),
cast_details AS (
    SELECT ci.movie_id, 
           STRING_AGG(DISTINCT CONCAT_WS(' as ', an.name, rt.role), ', ') AS cast_list
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id
)
SELECT mwi.title, mwi.production_year, mwi.movie_types, 
       mwi.keyword_count, cd.cast_list
FROM movies_with_info mwi
LEFT JOIN cast_details cd ON mwi.movie_id = cd.movie_id
ORDER BY mwi.production_year DESC, mwi.keyword_count DESC, mwi.title;
