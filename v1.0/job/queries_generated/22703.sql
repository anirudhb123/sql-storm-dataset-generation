WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastByCompany AS (
    SELECT 
        c.movie_id,
        ARRAY_AGG(DISTINCT co.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        ti.title,
        ti.production_year,
        CAST(COALESCE(ARRAY_AGG(DISTINCT ka.name), '{}') AS TEXT[]) AS alias_names,
        cb.companies,
        COUNT(DISTINCT ci.id) AS cast_count,
        MAX(ti.production_year) OVER () AS max_year
    FROM 
        RankedTitles ti
    LEFT JOIN 
        cast_info ci ON ti.title_id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        CastByCompany cb ON ti.title_id = cb.movie_id
    GROUP BY 
        ti.title_id, ti.title, ti.production_year, cb.companies
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN production_year < (SELECT AVG(production_year) FROM RankedTitles) 
            THEN 'Classic'
            ELSE 'Modern'
        END AS era,
        CASE 
            WHEN array_length(alias_names, 1) IS NULL THEN 'No Aliases'
            ELSE array_to_string(alias_names, ', ')
        END AS alias_summary
    FROM 
        MovieDetails
    WHERE 
        NOT (array_length(companies, 1) = 1 AND companies[1] IS NULL) 
        AND (cast_count > 5 OR production_year >= (SELECT MAX(production_year) - 20 FROM RankedTitles))
)
SELECT 
    era,
    COUNT(*) AS movie_count,
    MIN(production_year) AS earliest_movie,
    string_agg(DISTINCT alias_summary, '; ') AS all_aliases
FROM 
    FilteredMovies
GROUP BY 
    era
ORDER BY 
    era;
