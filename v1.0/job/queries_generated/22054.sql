WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
),
Directors AS (
    SELECT 
        p.id AS person_id,
        a.name AS director_name,
        COUNT(DISTINCT mc.id) AS total_movies_directed
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    JOIN 
        aka_name a ON a.person_id = mc.company_id
    JOIN 
        role_type rt ON rt.id = mc.company_type_id
    JOIN 
        cast_info ci ON ci.movie_id = mc.movie_id
    JOIN 
        person_info pi ON pi.person_id = ci.person_id
    JOIN 
        name n ON n.id = ci.person_id
    WHERE 
        rt.role = 'Director'
        AND n.gender IS NOT NULL
    GROUP BY 
        p.id, a.name
),
UniqueKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    d.director_name,
    COALESCE(uk.keywords, 'No Keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    Directors d ON tm.cast_count = (SELECT MAX(cast_count) FROM TopMovies)
LEFT JOIN 
    UniqueKeywords uk ON tm.movie_id = uk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;

This SQL query performs several complex operations, including:

- Common Table Expressions (CTEs) to break down the query into manageable parts.
- Window functions for ranking movies and counting the number of cast members per movie.
- LEFT JOINs to connect different entities while allowing for NULL values when no matches are found.
- A subquery to find unique movies being directed by the director with the maximum cast count.
- String aggregation to combine keywords associated with movies into a single string.
- Conditional logic to handle NULL values using `COALESCE`.
- Use of DISTINCT and GROUP BY clauses to ensure unique entries.
- A complex ORDER BY clause to determine the final sort order of the resulting dataset.

This query aims to create a comprehensive view of the top movies including their cast count, director names, and associated keywords, highlighting SQL's rich syntax and capabilities.
