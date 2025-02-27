WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(*) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL AND ak.person_id IS NOT NULL
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(*) > 10
),
FilteredMovies AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        pm.name AS popular_actor
    FROM 
        RankedMovies r
    LEFT JOIN 
        cast_info ci ON r.title_id = ci.movie_id
    LEFT JOIN 
        PopularActors pm ON ci.person_id = pm.person_id
    WHERE 
        r.rank_by_cast = 1
),
NullTitleCheck AS (
    SELECT 
        f.title,
        COALESCE(f.popular_actor, 'No Popular Actor') AS popular_actor,
        COUNT(m.id) AS companies_count,
        SUM(CASE WHEN m.note IS NULL THEN 1 ELSE 0 END) AS null_notes
    FROM 
        FilteredMovies f
    LEFT JOIN 
        movie_companies m ON f.title_id = m.movie_id
    GROUP BY 
        f.title, f.popular_actor
)

SELECT 
    nt.title,
    nt.popular_actor,
    nt.companies_count,
    nt.null_notes,
    CASE 
        WHEN nt.null_notes > 0 THEN 'Has Nulls'
        ELSE 'No Null Values'
    END AS null_status
FROM 
    NullTitleCheck nt
WHERE 
    nt.companies_count > (SELECT COUNT(*)/2 FROM movie_companies) 
ORDER BY 
    nt.companies_count DESC, nt.title;


This query accomplishes several sophisticated objectives:

1. **Common Table Expressions (CTEs)**: It uses multiple CTEs (RankedMovies, PopularActors, FilteredMovies, and NullTitleCheck) to break down the logic into manageable parts.
2. **Outer joins**: LEFT JOINs are utilized to ensure all potential matches are included, even if some tables do not have corresponding entries.
3. **Groupings with RANK()**: It involves window functions to rank movies based on the number of cast members.
4. **Subqueries**: Used in the HAVING clause to filter actors and in the WHERE clause to compare counts to half of total companies.
5. **NULL Handling**: Using `COALESCE` to address potential NULL values in the popular actor's name and counting NULLs in the notes.
6. **String manipulation**: String placeholders are used for clarity in NULL handling, capturing NULL logic elegantly.
7. **Conditional logic with `CASE`**: This constructs a conditional column based on whether any NULL notes exist.
8. **Complex conditions for filtering**: Includes both counts and rankings, adding depth to join conditions to filter the results accurately.

The resulting output will provide a comprehensive view of movies with the most prevalent actors, the number of companies associated, and the presence of NULL notes, ultimately evaluating rows against a dynamic reference point.
