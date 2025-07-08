
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
), 
FilteredCast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role IS NOT NULL
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(fc.actor_count, 0) AS actor_count,
    COALESCE(cm.company_names, ARRAY_CONSTRUCT()) AS companies,
    CASE 
        WHEN rm.rank_by_title <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS title_rank_group
FROM 
    RankedMovies rm
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(person_id) AS actor_count
    FROM 
        FilteredCast
    GROUP BY 
        movie_id
) fc ON rm.movie_id = fc.movie_id
LEFT JOIN CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.title;
