WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt2.title, 'No Parent') AS parent_title,
        0 AS level
    FROM 
        aka_title mt
    LEFT JOINaka_title mt2 ON mt.episode_of_id = mt2.id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(mt2.title, 'No Parent') AS parent_title,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_title,
    mh.level,
    COUNT(DISTINCT cc.person_id) AS cast_count,
    AVG(pi.notes_length) AS avg_info_length,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.country_code IS NOT NULL) AS company_names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    company_name cn ON cn.id IN (SELECT mc.company_id 
                                   FROM movie_companies mc 
                                   WHERE mc.movie_id = mh.movie_id)
LEFT JOIN 
    (SELECT 
         person_id,
         COUNT(note) AS notes_length
     FROM 
         person_info 
     GROUP BY 
         person_id) pi ON pi.person_id = cc.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.parent_title, mh.level
ORDER BY 
    mh.production_year DESC, mh.title
LIMIT 100
OFFSET 0;

-- This query benchmarks performance by ...
-- 1. Building a recursive CTE to explore hierarchical relationships among movies.
-- 2. Joining various tables to gather diverse metrics including cast count, average info length, keywords, and company names.
-- 3. Incorporating aggregation and filtering through window functions and conditional logic.
-- 4. Utilizing substring searches, NULL checks, and comprehensive ORDER BY clauses to challenge the chosen execution plan efficiently.
