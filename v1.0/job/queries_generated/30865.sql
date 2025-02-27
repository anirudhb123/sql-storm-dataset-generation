WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
        JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
        JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.depth < 3
),
cast_rating AS (
    SELECT 
        ci.movie_id,
        r.role AS role,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
        JOIN role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info ORDER BY mi.info_type_id) AS info_summary
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
ranked_movies AS (
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        COALESCE(cr.actor_count, 0) AS actor_count,
        COALESCE(mi.info_summary, 'No Info Available') AS info_summary,
        ROW_NUMBER() OVER (ORDER BY h.production_year DESC, actor_count DESC) AS movie_rank
    FROM 
        movie_hierarchy h
        LEFT JOIN cast_rating cr ON h.movie_id = cr.movie_id
        LEFT JOIN movie_info_summary mi ON h.movie_id = mi.movie_id
)
SELECT 
    r.movie_rank,
    r.title,
    r.production_year,
    r.actor_count,
    r.info_summary,
    CASE 
        WHEN r.production_year IS NULL THEN 'Unknown Year'
        ELSE 'Year ' || r.production_year
    END AS production_year_description
FROM 
    ranked_movies r
WHERE 
    r.actor_count > 0
    AND r.movie_rank <= 10
ORDER BY 
    r.movie_rank;
