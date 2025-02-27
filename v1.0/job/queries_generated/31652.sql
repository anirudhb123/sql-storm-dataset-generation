WITH RECURSIVE movie_hierarchy AS (
    SELECT id AS movie_id, title, production_year, NULL::integer AS parent_movie_id
    FROM aka_title
    WHERE production_year >= 2000

    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, mh.movie_id AS parent_movie_id
    FROM movie_link ml
    JOIN aka_title m ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE((SELECT STRING_AGG(DISTINCT cn.name, ', ') 
               FROM char_name cn 
               JOIN cast_info ci ON ci.movie_id = m.id
               WHERE ci.person_id = cn.imdb_id), 'No Cast') AS cast_names,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = m.id) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_rank,
    CASE 
        WHEN m.production_year IS NULL THEN 'Unknown Year'
        WHEN m.production_year < 2010 THEN 'Before 2010'
        ELSE 'After 2010'
    END AS year_group,
    mg.name AS production_company
FROM movie_hierarchy m
LEFT JOIN movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN company_name mg ON mc.company_id = mg.imdb_id
WHERE 
    m.production_year IS NOT NULL 
    AND m.title IS NOT NULL
    AND EXISTS (SELECT 1 FROM cast_info ci WHERE ci.movie_id = m.movie_id AND ci.note IS NOT NULL)
ORDER BY 
    m.title;

