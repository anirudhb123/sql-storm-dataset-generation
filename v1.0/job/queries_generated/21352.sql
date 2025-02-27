WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        AVG(ci.nr_order) OVER (PARTITION BY t.id) AS avg_order
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id 
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id 
    WHERE 
        t.production_year IS NOT NULL
),
GenreCounts AS (
    SELECT 
        t.id AS title_id,
        COUNT(DISTINCT m.id) AS num_genres
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        t.id
),
CombinedResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.title_rank,
        gc.num_genres,
        CASE 
            WHEN rm.avg_order IS NULL THEN 'No Cast' 
            ELSE CAST(rm.avg_order AS VARCHAR(20))
        END AS avg_cast_order
    FROM 
        RankedMovies rm
    LEFT JOIN 
        GenreCounts gc ON rm.title_id = gc.title_id
)
SELECT 
    title,
    production_year,
    title_rank,
    num_genres,
    CASE 
        WHEN num_genres > 3 THEN 'Diverse Genre'
        WHEN title_rank = 1 AND num_genres IS NOT NULL THEN 'Top Movie of Year'
        ELSE 'Regular Movie'
    END AS classification
FROM 
    CombinedResults
WHERE 
    (num_genres IS NOT NULL AND num_genres < 5) 
    OR (avg_cast_order IS NOT NULL AND avg_cast_order = 'No Cast')
ORDER BY 
    production_year DESC, title_rank;

This SQL query incorporates various concepts:

1. **Common Table Expressions (CTE)**: `RankedMovies`, `GenreCounts`, and `CombinedResults` are used to structure the query logically.
2. **Window Functions**: `ROW_NUMBER()` and `AVG()` functions to calculate movie rankings and average cast order.
3. **Outer Joins**: Left joins to incorporate movies that may lack casting or genre data.
4. **Complicated Predicates & CASE Logic**: Different classifications based on the number of genres and ranking.
5. **NULL Logic**: Handling for potential NULL values in a meaningful way, especially in the average cast order and genre counts.
6. **Distinct Counts**: Handling of unique genre counts for each title.
7. **Ordering**: Final results are ordered by year descending and rank ascending for clarity.

This demonstrates advanced SQL capabilities and explores various semantic outcomes and corner cases.
