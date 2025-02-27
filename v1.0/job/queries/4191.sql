
WITH movie_years AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
ranked_movies AS (
    SELECT 
        my.movie_id,
        my.title,
        my.production_year,
        my.company_count,
        RANK() OVER (PARTITION BY my.production_year ORDER BY my.company_count DESC) AS rank_within_year
    FROM 
        movie_years my
),
cast_role_info AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    c.role,
    c.actor_count,
    mk.keywords,
    CASE 
        WHEN rm.company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Available'
    END AS company_availability
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_role_info c ON rm.movie_id = c.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_within_year <= 5
    AND (c.actor_count > 5 OR c.actor_count IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.company_count DESC;
