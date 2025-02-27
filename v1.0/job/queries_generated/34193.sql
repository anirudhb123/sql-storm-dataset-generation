WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
)
, ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank_within_level
    FROM movie_hierarchy mh
)
SELECT
    ak.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    rml.level AS movie_level,
    rml.rank_within_level,
    co.name AS company_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ti.production_year) OVER () AS median_production_year
FROM cast_info ci
JOIN aka_name ak ON ci.person_id = ak.person_id
JOIN title ti ON ci.movie_id = ti.id
LEFT JOIN movie_companies mc ON ti.id = mc.movie_id
LEFT JOIN company_name co ON mc.company_id = co.id
LEFT JOIN movie_keyword mk ON ti.id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
JOIN ranked_movies rml ON ti.id = rml.movie_id
WHERE 
    ti.production_year > 2000
    AND ak.name IS NOT NULL
    AND (co.country_code IS NULL OR co.country_code != 'USA')
GROUP BY 
    ak.name, 
    ti.title,
    ti.production_year,
    rml.level, 
    rml.rank_within_level, 
    co.name
ORDER BY 
    rml.level, 
    rml.rank_within_level;

