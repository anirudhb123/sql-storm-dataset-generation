WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FullCastInfo AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER(PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MoviesWithCompilations AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(GROUP_CONCAT(c.name), 'No Companies') AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id
),
FilteredTitles AS (
    SELECT 
        ft.title_id,
        t.title,
        ft.year_rank,
        COALESCE(fc.companies, 'Unknown Company') AS companies,
        fc.actor_name,
        fc.role_name,
        fc.actor_rank
    FROM 
        RankedTitles ft
    LEFT JOIN 
        MoviesWithCompilations fc ON ft.title_id = fc.movie_id
    WHERE 
        ft.year_rank <= 3
)
SELECT 
    title_id,
    title,
    production_year,
    companies,
    actor_name,
    role_name,
    actor_rank
FROM 
    FullCastInfo f  
FULL OUTER JOIN 
    FilteredTitles ft 
ON 
    f.movie_id = ft.title_id 
WHERE 
    (f.actor_rank IS NULL OR f.actor_rank BETWEEN 1 AND 5) 
    AND (ft.companies IS NOT NULL OR ft.companies = 'No Companies')
ORDER BY 
    ft.production_year DESC,
    ft.title ASC,
    f.actor_rank ASC
LIMIT 100 OFFSET 10;

This query demonstrates the use of Common Table Expressions (CTEs) to structure well-defined segments, which include:

1. **RankedTitles**: This ranks titles based on production year and title within that year.
2. **FullCastInfo**: This retrieves and ranks cast information for each movie.
3. **MoviesWithCompilations**: This pulls movie data along with associated company details, handling cases with no associated companies.
4. **FilteredTitles**: This filters titles ranked by year, extracting relevant movie information.

The final selection employs a full outer join between the full cast information and the filtered movie titles, using a mix of complicated predicates and COALESCE for handling NULL values. It also incorporates ordered results, limiting the output set to specifically delineate the results.
