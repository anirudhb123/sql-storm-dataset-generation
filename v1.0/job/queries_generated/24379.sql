WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id 
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id 
    GROUP BY 
        mt.title, mt.production_year
),
FilteredTitles AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_per_year <= 3
),
MovieNotes AS (
    SELECT 
        mt.title AS movie_title,
        GROUP_CONCAT(DISTINCT mi.info) AS notes
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id 
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mt.title
),
FinalResults AS (
    SELECT 
        ft.title, 
        ft.production_year, 
        ft.actor_count, 
        mn.notes,
        COALESCE(ft.actor_count * 1000 / NULLIF((SELECT COUNT(DISTINCT person_id) FROM person_info pi), 0), 0) AS actor_density
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        MovieNotes mn ON ft.title = mn.movie_title
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.notes,
    CASE 
        WHEN fr.actor_density IS NULL THEN 'Density Not Available' 
        ELSE CAST(fr.actor_density AS TEXT) 
    END AS actor_density
FROM 
    FinalResults fr
WHERE 
    fr.notes IS NOT NULL 
    AND fr.production_year BETWEEN 1980 AND 2000 
ORDER BY 
    fr.production_year DESC, 
    fr.actor_density DESC NULLS LAST;

This elaborate SQL query includes:
- Common Table Expressions (CTEs) to partition and filter data (`RankedMovies`, `FilteredTitles`, `MovieNotes`, and `FinalResults`).
- Outer joins to include titles without actors, and aggregate notes.
- Window function to rank movies by actor count per production year.
- Use of `COALESCE` and `NULLIF` to calculate actor density while handling potential division by zero.
- String aggregation with `GROUP_CONCAT` for combining notes.
- Complicated predicates and expressions in the final selection and ordering. 
- NULL handling to provide a user-friendly message when the actor density is not available.
