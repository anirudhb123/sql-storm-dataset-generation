WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(SUM(CASE WHEN ci.note LIKE '%Lead%' THEN 1 ELSE 0 END), 0) AS lead_count,
        COUNT(ci.id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, SUM(CASE WHEN ci.note LIKE '%Lead%' THEN 1 ELSE 0 END) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id
),
LeadActorsInfo AS (
    SELECT 
        ak.name AS lead_actor,
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.lead_count
    FROM 
        RankedMovies rm
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ci.note ILIKE '%Lead%' AND rm.lead_count > 0
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        rm.movie_id, rm.title
),
FinalResults AS (
    SELECT 
        lw.movie_id,
        lw.title,
        lw.production_year,
        lw.lead_actor,
        lw.lead_count,
        mw.keywords,
        CASE 
            WHEN lw.production_year IS NULL THEN 'Unknown Year'
            WHEN lw.production_year < 2000 THEN 'Classic'
            ELSE 'Modern'
        END AS era,
        COUNT(*) OVER (PARTITION BY lw.production_year) AS movies_in_year
    FROM 
        LeadActorsInfo lw
    LEFT JOIN 
        MoviesWithKeywords mw ON lw.movie_id = mw.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.lead_actor,
    fr.keywords,
    fr.era,
    fr.movies_in_year
FROM 
    FinalResults fr
WHERE 
    (fr.lead_count > 2 OR fr.keywords IS NOT NULL)
    AND fr.production_year >= 1990
ORDER BY 
    fr.production_year DESC, fr.lead_count DESC
LIMIT 100;

This SQL query employs various constructs such as Common Table Expressions (CTEs) for modularizing logic, as well as window functions for ranking movies. It uses outer joins to gather necessary data while managing NULL values, and it showcases string aggregations for keywords. The final result is filtered based on specific criteria and ordered by production year and lead counts, aiming to provide a concise list of relevant movies.
