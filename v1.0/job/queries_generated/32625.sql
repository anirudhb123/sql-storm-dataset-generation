WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        ARRAY[mt.title] AS title_path
    FROM 
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL -- Starting with the top-level movies
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mh.level + 1,
        mh.title_path || mt.title
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id -- Recursively joining to get episodes
),
movie_stats AS (
    SELECT 
        m.movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword) AS total_keywords,
        AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length
    FROM 
        movie_hierarchy mh 
    JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY 
        mh.movie_id, mh.title
)
SELECT 
    ms.title,
    ms.total_cast,
    ms.total_keywords,
    ms.avg_info_length,
    COALESCE(cn.name, 'No Company') AS production_company,
    ROW_NUMBER() OVER (ORDER BY ms.total_cast DESC) AS cast_rank
FROM 
    movie_stats ms
LEFT JOIN 
    movie_companies mc ON ms.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    ms.total_cast > 5 -- Filtering to include only movies with more than 5 cast members
ORDER BY 
    ms.total_cast DESC, 
    ms.title ASC
LIMIT 10;

-- Explanation:
-- The first CTE `movie_hierarchy` recursively fetches movies and their episodes, building a hierarchy.
-- The second CTE `movie_stats` gathers statistics such as total cast members, total keywords, and average info length for each main movie.
-- Finally, we select from `movie_stats`, joining with movie companies, to get the necessary movie statistics and include company names, while filtering for movies with more than 5 cast members and ordering results.
