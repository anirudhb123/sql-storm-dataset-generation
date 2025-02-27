WITH recursive movie_hierarchy AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.kind_id, 
           COALESCE(k.keyword, 'No Keywords') AS keyword,
           1 AS level
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year IS NOT NULL

    UNION ALL

    SELECT t2.id AS title_id, t2.title, t2.production_year, t2.kind_id, 
           COALESCE(k2.keyword, 'No Keywords') AS keyword,
           mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON ml.movie_id = mh.title_id
    JOIN aka_title t2 ON t2.id = ml.linked_movie_id
    LEFT JOIN movie_keyword mk2 ON mk2.movie_id = t2.id
    LEFT JOIN keyword k2 ON k2.id = mk2.keyword_id
    WHERE t2.production_year IS NOT NULL
),
filtered_movies AS (
    SELECT title_id, title, production_year, keyword,
           ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY level DESC) AS rn
    FROM movie_hierarchy
    WHERE keyword IS NOT NULL
),
aggregated_movies AS (
    SELECT production_year, 
           STRING_AGG(DISTINCT title, '; ') AS titles,
           COUNT(*) AS movie_count
    FROM filtered_movies
    WHERE rn <= 10
    GROUP BY production_year
)
SELECT am.production_year,
       am.titles,
       am.movie_count,
       (SELECT COUNT(DISTINCT ci.person_id) 
        FROM cast_info ci 
        JOIN aka_title at ON at.id = ci.movie_id
        WHERE at.production_year = am.production_year) AS distinct_cast_count,
       (CASE 
            WHEN (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id IN 
                          (SELECT title_id FROM filtered_movies WHERE production_year = am.production_year)) > 5 
            THEN 'High Production' 
            ELSE 'Low Production' 
        END) AS production_label
FROM aggregated_movies am
LEFT JOIN movie_info mi ON mi.movie_id IN (SELECT title_id FROM filtered_movies WHERE production_year = am.production_year)
WHERE (SELECT COUNT(DISTINCT info_type_id) FROM movie_info mi2 WHERE mi2.movie_id IN 
          (SELECT title_id FROM filtered_movies WHERE production_year = am.production_year)) > 2
GROUP BY am.production_year, am.titles, am.movie_count
ORDER BY am.production_year DESC
LIMIT 20;

