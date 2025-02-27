WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(CASE WHEN kw.keyword IS NOT NULL THEN 1 END) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.year_rank,
        COALESCE(c.name, 'Unknown') AS company_name,
        COALESCE(ci.role, 'N/A') AS role_type,
        r.keyword_count,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = r.movie_id) AS total_cast_members
    FROM 
        RankedMovies r
    LEFT JOIN 
        movie_companies mc ON r.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id
    WHERE 
        r.year_rank <= 10 
        AND (r.keyword_count > 0 OR r.production_year > 2000)
),
DistinctRoles AS (
    SELECT DISTINCT
        role_id,
        COUNT(*) OVER (PARTITION BY role_id) AS role_count,
        (SELECT COUNT(DISTINCT person_id) FROM cast_info ci2 WHERE ci2.role_id = ci.role_id) AS unique_actors
    FROM 
        cast_info ci
    WHERE 
        ci.nr_order IS NOT NULL
),
CompanyRoles AS (
    SELECT 
        md.movie_id,
        md.title,
        md.company_name,
        dr.role_id,
        dr.role_count,
        dr.unique_actors
    FROM 
        MovieDetails md
    JOIN 
        DistinctRoles dr ON md.movie_id = dr.role_id
)
SELECT 
    cr.title,
    cr.production_year,
    cr.company_name,
    cr.role_count,
    cr.unique_actors,
    CASE 
        WHEN cr.unique_actors > 10 THEN 'Ensemble Cast'
        WHEN cr.unique_actors BETWEEN 5 AND 10 THEN 'Moderate Cast'
        WHEN cr.unique_actors < 5 THEN 'Minimal Cast'
        ELSE 'Unknown'
    END AS cast_category,
    STRING_AGG(DISTINCT ci.person_id::TEXT, ', ') AS actor_ids
FROM 
    CompanyRoles cr
LEFT JOIN 
    cast_info ci ON cr.movie_id = ci.movie_id
GROUP BY 
    cr.title,
    cr.production_year,
    cr.company_name,
    cr.role_count,
    cr.unique_actors
HAVING 
    SUM(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) = 0 -- No NULL orders
ORDER BY 
    cr.production_year DESC, 
    cr.role_count DESC;
