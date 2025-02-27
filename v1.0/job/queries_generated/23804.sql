WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        aka_name a ON a.id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
TotalRoles AS (
    SELECT 
        c.movie_id,
        COUNT(c.role_id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON k.id = m.keyword_id
    GROUP BY 
        m.movie_id
),
MoviesWithCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        tr.role_count,
        kw.keywords,
        mc.companies
    FROM 
        RankedTitles rt
    LEFT OUTER JOIN 
        TotalRoles tr ON rt.title_id = tr.movie_id
    LEFT JOIN 
        MoviesWithKeywords kw ON rt.title_id = kw.movie_id
    LEFT JOIN 
        MoviesWithCompanies mc ON rt.title_id = mc.movie_id
    WHERE 
        rt.year_rank <= 5 
        AND (tr.role_count IS NULL OR tr.role_count > 2)
)
SELECT 
    fm.title,
    fm.production_year,
    fm.role_count,
    fm.keywords,
    COALESCE(fm.companies, 'No companies listed') AS companies
FROM 
    FilteredMovies fm
WHERE 
    fm.title IS NOT NULL
ORDER BY 
    fm.production_year DESC, fm.role_count DESC;

-- For obscure semantics, let's add a condition to filter out titles that start with a vowel and production_year divides by 5
-- Just to avoid overlapping with the most common selections
AND NOT (fm.title ILIKE 'A%' OR fm.title ILIKE 'E%' OR fm.title ILIKE 'I%' OR fm.title ILIKE 'O%' OR fm.title ILIKE 'U%')
AND (fm.production_year % 5) = 0
This query demonstrates the use of Common Table Expressions (CTEs) for organizing and breaking down the complex logic, including window functions, string aggregation, and various join types with some unusual filtering. It also incorporates edge cases such as checking for NULL values and bizarre conditions related to title semantics and production year divisibility.
