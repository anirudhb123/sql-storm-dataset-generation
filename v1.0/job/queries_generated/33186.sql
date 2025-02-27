WITH RECURSIVE movie_hierarchy AS (
    -- This CTE will create a hierarchy of movies based on episodes.
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
-- This CTE retrieves top cast based on their roles for each movie.
top_cast AS (
    SELECT 
        cc.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        RANK() OVER (PARTITION BY cc.movie_id ORDER BY cc.nr_order) AS cast_rank
    FROM 
        cast_info cc
    JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    WHERE 
        cc.note IS NULL
),
-- This CTE collects metadata for movie companies.
company_info AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    tc.actor_name,
    ci.company_name,
    ci.company_type,
    ci.num_companies,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    top_cast tc ON mh.movie_id = tc.movie_id AND tc.cast_rank <= 3  -- Get top 3 cast
LEFT JOIN 
    company_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year IS NOT NULL AND
    mh.production_year > 2000  -- Filtering for movies post-2000
GROUP BY 
    mh.title, 
    mh.production_year,
    tc.actor_name,
    ci.company_name,
    ci.company_type
ORDER BY 
    mh.production_year DESC, 
    keyword_count DESC,
    tc.actor_name;  -- Order by production year, keyword count and actor name

