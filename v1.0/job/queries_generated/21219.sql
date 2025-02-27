WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        at.kind_id,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM
        aka_title at
    LEFT JOIN
        movie_companies mc ON at.id = mc.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year, at.kind_id
), 
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.year_rank,
        kt.kind AS movie_kind,
        COALESCE(NULLIF(rm.production_company_count, 0), 1) AS adjusted_company_count
    FROM 
        RankedMovies rm
    JOIN 
        kind_type kt ON rm.kind_id = kt.id
    WHERE 
        rm.year_rank <= 5
        AND rm.production_year > (SELECT AVG(production_year) FROM aka_title)
), 
TopMoviesWithRoles AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.movie_kind,
        STRING_AGG(DISTINCT CONCAT('Role: ', rt.role, ' - Count: ', cnt), '; ') AS roles_summary
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON fm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS cnt
        FROM 
            cast_info
        GROUP BY 
            movie_id
    ) role_counts ON ci.movie_id = role_counts.movie_id
    GROUP BY 
        fm.title, fm.production_year, fm.movie_kind
)
SELECT 
    movie_summary.title,
    movie_summary.production_year,
    movie_summary.movie_kind,
    movie_summary.roles_summary,
    (SELECT COUNT(*) FROM info_type it WHERE it.id IN (SELECT DISTINCT info_type_id FROM movie_info mi WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = movie_summary.title LIMIT 1))) AS associated_info_types,
    CASE 
        WHEN movie_summary.production_year IS NULL THEN 'Unknown Year'
        ELSE movie_summary.production_year::text
    END AS year_text
FROM 
    TopMoviesWithRoles movie_summary
WHERE 
    movie_summary.roles_summary IS NOT NULL
ORDER BY 
    movie_summary.production_year DESC, 
    movie_summary.title;
