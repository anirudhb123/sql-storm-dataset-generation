WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(p.name, 'Unknown') AS producer_name,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name p ON mc.company_id = p.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Producer')
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(p.name, 'Unknown') AS producer_name,
        m.production_year,
        h.level + 1
    FROM 
        movie_hierarchy h
    JOIN 
        aka_title m ON h.movie_id = m.episode_of_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name p ON mc.company_id = p.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Producer')
),
    
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.producer_name,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rnk
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.level <= 2 -- Limiting levels to avoid deep hierarchy
),
    
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    r.movie_title,
    r.producer_name,
    r.production_year,
    r.keywords,
    COALESCE(pr.info, 'No Info') AS production_info
FROM 
    ranked_movies r
LEFT JOIN 
    movie_info pr ON r.movie_id = pr.movie_id AND pr.info_type_id = (SELECT id FROM info_type WHERE info = 'Production Year')
LEFT JOIN 
    movie_keywords mk ON r.movie_id = mk.movie_id
WHERE 
    r.production_year >= 2000
ORDER BY 
    r.production_year DESC, r.rnk
LIMIT 10;

This SQL query performs a complex task of extracting movie details, including producer names, production years, and associated keywords using a recursive CTE to establish a hierarchy of episodes and their corresponding titles, coupled with window functions to rank them. It utilizes various joins and NULL handling for a comprehensive result set, suitable for performance benchmarking.
