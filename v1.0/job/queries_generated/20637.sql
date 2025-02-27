WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        CTE_Persons.role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ca.nr_order) AS role_order
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    JOIN 
        role_type CTE_Persons ON ca.role_id = CTE_Persons.id
    WHERE 
        t.production_year IS NOT NULL AND 
        t.production_year > 2000
),

TopMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        MovieDetails m
    JOIN 
        cast_info c ON m.title = c.note  -- assuming 'note' refers to title
    GROUP BY 
        m.title, m.production_year
    HAVING 
        COUNT(DISTINCT mk.keyword) >= 5
),

RankedMovies AS (
    SELECT 
        title,
        production_year,
        keyword_count,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC, keyword_count DESC) AS movie_rank
    FROM 
        TopMovies
    WHERE 
        keyword_count <= 10 AND                           -- bizarre constraint
        production_year IS NOT DISTINCT FROM 2021         -- NULL logic corner case
)

SELECT 
    rm.title,
    rm.production_year,
    rm.keyword_count,
    rm.cast_count,
    COALESCE(SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END), 0) AS null_notes_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS collected_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_keyword mk ON rm.title = mk.movie_id  -- assuming title can identify movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    cast_info c ON c.movie_id = rm.title  -- join on cast for additional context
GROUP BY 
    rm.title, rm.production_year, rm.keyword_count, rm.cast_count
ORDER BY 
    rm.movie_rank;

In this query:

1. **Common Table Expressions (CTEs)** are used to break the query into manageable pieces for clarity:
   - `MovieDetails` gathers detailed movie and casting information.
   - `TopMovies` filters those movies down based on certain criteria regarding the number of keywords and distinct cast members, along with bizarre constraints for analytical purposes.
   - `RankedMovies` ranks the movies according to the number of cast members and keywords while demonstrating NULL logic.

2. I employed various SQL constructs:
   - **Joins**: Including `LEFT JOIN` to include entries with NULL values.
   - **Window functions**: `ROW_NUMBER()` and `RANK()` to generate ranks based on counts.
   - **Aggregate Functions**: Using `COUNT()` and `STRING_AGG()` to collect and count results.
   - **COALESCE**: To handle NULL logic in counting cast members with NULL notes.

3. Odd constraints and logic were introduced in HAVING and WHERE clauses to emphasize unusual use cases in SQL semantics and corner cases involving NULLs.
