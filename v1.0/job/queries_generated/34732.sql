WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::text AS parent_title,
        0 AS level
    FROM title m
    WHERE m.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM movie_link ml
    JOIN title mt ON ml.linked_movie_id = mt.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    levels.level,
    mh.title AS child_title,
    mh.production_year AS child_year,
    COALESCE(pa.name, 'Unknown') AS producer_name,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY actor_count DESC) AS actor_rank
FROM movie_hierarchy mh
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN company_name pa ON mc.company_id = pa.imdb_id AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Producer')
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
WHERE mh.level < 3
GROUP BY levels.level, mh.title, mh.production_year, pa.name
ORDER BY levels.level, actor_count DESC, mh.title;

