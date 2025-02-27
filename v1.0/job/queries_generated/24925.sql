WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank,
        COUNT(DISTINCT kc.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year IS NOT NULL
), FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5 OR EXISTS (
            SELECT 1
            FROM movie_info mi
            WHERE
                mi.movie_id = rm.movie_id
                AND mi.info LIKE '%Award%'
        )
), MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.keyword_count,
        COALESCE(CAST(p.info AS VARCHAR), 'No info available') AS additional_info
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_info p ON fm.movie_id = p.movie_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
), FinalReport AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword_count,
        md.additional_info,
        CASE 
            WHEN md.keyword_count > 10 THEN 'High'
            WHEN md.keyword_count BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS keyword_category,
        (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = md.movie_id) AS company_count
    FROM 
        MovieDetails md
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.keyword_count,
    fr.keyword_category,
    fr.additional_info,
    CASE 
        WHEN fr.company_count = 0 THEN 'Independent'
        WHEN fr.company_count BETWEEN 1 AND 3 THEN 'Small Studio'
        ELSE 'Large Studio'
    END AS studio_category
FROM 
    FinalReport fr
ORDER BY 
    fr.production_year DESC, fr.keyword_count DESC;

-- Additional bizarre query component making use of string manipulation and NULL semantics
WITH NullLogic AS (
    SELECT DISTINCT
        COALESCE(NULLIF(name, ''), 'Unknown') AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_acted_in
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        COALESCE(NULLIF(an.name, ''), 'Unknown')
)
SELECT 
    nl.actor_name,
    nl.movies_acted_in,
    CASE 
        WHEN nl.movies_acted_in > 5 THEN 'Prolific Actor'
        WHEN nl.movies_acted_in BETWEEN 1 AND 5 THEN 'Emerging Actor'
        ELSE 'Unknown Actor'
    END AS actor_status
FROM 
    NullLogic nl
WHERE 
    nl.actor_name IS NOT NULL
ORDER BY 
    nl.movies_acted_in DESC;
