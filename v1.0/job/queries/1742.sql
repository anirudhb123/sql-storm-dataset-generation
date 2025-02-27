WITH movie_roles AS (
    SELECT 
        c.movie_id,
        c.role_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, c.role_id, r.role
),
movie_information AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        CASE 
            WHEN m.production_year IS NULL THEN 'Unknown Year'
            ELSE CAST(m.production_year AS TEXT)
        END AS year_string
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
),
director_movies AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind = 'Director'
    GROUP BY 
        mc.movie_id
),
ranked_movies AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        dr.company_count,
        RANK() OVER (PARTITION BY mi.production_year ORDER BY dr.company_count DESC) AS rank_within_year
    FROM 
        movie_information mi
    LEFT JOIN 
        director_movies dr ON mi.movie_id = dr.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(roles.role_count, 0) AS total_roles,
    rm.company_count,
    CASE 
        WHEN rm.rank_within_year <= 10 THEN 'Top 10'
        ELSE 'Not in Top 10'
    END AS top_rank_status
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_roles roles ON rm.movie_id = roles.movie_id
WHERE 
    rm.company_count IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.company_count DESC;
