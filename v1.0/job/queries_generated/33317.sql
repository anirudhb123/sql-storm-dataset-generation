WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL 

    UNION ALL 

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
ranked_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
),
movie_keyword_cte AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
merged_data AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        rc.actor_name,
        CASE 
            WHEN rc.actor_rank <= 3 THEN 'Top Cast'
            ELSE 'Supporting Cast'
        END AS cast_role,
        NULLIF(mkc.keyword_count, 0) AS keyword_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        ranked_cast rc ON mh.movie_id = rc.movie_id
    LEFT JOIN 
        movie_keyword_cte mkc ON mh.movie_id = mkc.movie_id
),
final_selection AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        CAST(actor_name AS text) AS actor_name,
        cast_role,
        COALESCE(keyword_count, 0) AS total_keywords,
        COUNT(DISTINCT actor_name) OVER (PARTITION BY movie_id) AS total_cast
    FROM 
        merged_data
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actor_name,
    cast_role,
    total_keywords,
    total_cast
FROM 
    final_selection
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, total_keywords DESC, actor_name;
