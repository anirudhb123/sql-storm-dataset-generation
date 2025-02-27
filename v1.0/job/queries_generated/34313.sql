WITH RECURSIVE actor_hierarchy AS (
    -- Base CTE to get the initial set of actors (top-level)
    SELECT 
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL

    UNION ALL 
    
    -- CTE recursion to get the hierarchy (if applicable)
    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info c ON ah.person_id = c.person_id -- Self join on cast_info to find related actors
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),

movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS companies_count,
        AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) END) AS avg_info_length
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),

ranked_movies AS (
    SELECT 
        md.*,
        DENSE_RANK() OVER (PARTITION BY production_year ORDER BY companies_count DESC) AS company_rank,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, companies_count DESC) AS movie_rank
    FROM 
        movie_data md
)

SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.companies_count,
    rm.avg_info_length,
    ah.actor_name,
    ah.level,
    CASE 
        WHEN rm.companies_count IS NULL THEN 'No companies involved'
        ELSE 'Companies involved'
    END AS company_status
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_hierarchy ah ON rm.movie_id IN (
        SELECT DISTINCT movie_id FROM cast_info WHERE person_id = ah.person_id
    )
WHERE 
    rm.movie_rank <= 10 -- Top 10 movies based on filtering criteria
ORDER BY 
    rm.production_year DESC, rm.companies_count DESC, ah.level;
