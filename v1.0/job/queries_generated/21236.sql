WITH movie_years AS (
    SELECT 
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.production_year
),
role_summary AS (
    SELECT 
        ci.role_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.role_id
),
title_keyword AS (
    SELECT 
        mt.id AS movie_id,
        array_agg(mk.keyword) AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
final_summary AS (
    SELECT 
        mt.title,
        mt.production_year,
        COALESCE(my.company_count, 0) AS company_count,
        COALESCE(rs.actor_count, 0) AS actor_count,
        COALESCE(tk.keywords, '{}') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_years my ON mt.production_year = my.production_year
    LEFT JOIN 
        role_summary rs ON rs.role_id = (
            SELECT 
                role_id 
            FROM 
                cast_info ci 
            WHERE 
                ci.movie_id = mt.id 
            LIMIT 1
        )
    LEFT JOIN 
        title_keyword tk ON mt.id = tk.movie_id
    WHERE 
        (mt.production_year IS NOT NULL AND mt.production_year > 2000) 
        OR (my.company_count < 5 AND mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie'))
)

SELECT 
    title,
    production_year,
    actor_count,
    company_count,
    keywords
FROM 
    final_summary
WHERE 
    actor_count > 0
ORDER BY 
    production_year DESC, 
    actor_count DESC
LIMIT 100;

-- Additional peculiarities:
-- NULL handling with COALESCE for company_count and actor_count
-- The use of array_agg() to create an aggregated list of keywords
-- Correlated subquery for fetching role_id
-- Use of unusual conditions in the WHERE clause employing both production year and company count
