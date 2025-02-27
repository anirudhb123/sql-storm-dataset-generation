WITH RecursiveMovieInfo AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        COALESCE(ki.kind, 'Unknown') AS kind,
        m.production_year,
        w.actor_count,
        m.note,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        title m ON t.movie_id = m.id
    LEFT JOIN 
        (SELECT 
             movie_id, 
             COUNT(DISTINCT ci.person_id) AS actor_count 
         FROM 
             cast_info ci 
         GROUP BY 
             movie_id) w ON m.id = w.movie_id
    LEFT JOIN 
        kind_type ki ON m.kind_id = ki.id
    WHERE 
        m.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title, 
        production_year,
        kind,
        actor_count,
        note
    FROM 
        RecursiveMovieInfo
    WHERE 
        actor_count > (SELECT AVG(actor_count) FROM RecursiveMovieInfo WHERE actor_count IS NOT NULL)
),
MovieKeywords AS (
    SELECT 
        fk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword fk
    JOIN 
        keyword k ON fk.keyword_id = k.id
    GROUP BY 
        fk.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.kind,
    fm.actor_count,
    fm.note,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
WHERE 
    fm.production_year BETWEEN 2000 AND 2023
    AND (fm.note IS NULL OR fm.note NOT LIKE '%uncertain%')
ORDER BY 
    fm.production_year DESC, 
    fm.title 
FETCH FIRST 50 ROWS ONLY;

This query includes:
1. Common Table Expressions (CTEs) for recursion and filtering.
2. Filtering based on a correlated subquery for average actor counts.
3. Aggregate functions to gather keywords associated with movies.
4. NULL handling with `COALESCE` for default values.
5. An assortment of joins, including outer joins, to make the results comprehensive.
6. Filtering and ordering logic that includes edge cases for notes and production years.
