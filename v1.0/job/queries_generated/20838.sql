WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title a 
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),

HighCastMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),

GenreKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)

SELECT 
    h.title,
    h.production_year,
    h.cast_count,
    COALESCE(g.keywords, 'No Keywords') AS keywords,
    COALESCE(STRING_AGG(DISTINCT CONCAT(cn.name, ' (', ct.kind, ')'), '; '), 'No Companies') AS companies
FROM 
    HighCastMovies h
LEFT JOIN 
    movie_companies mc ON mc.movie_id IN (SELECT id FROM aka_title WHERE production_year = h.production_year)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    GenreKeywords g ON g.movie_id = h.id
GROUP BY 
    h.title, h.production_year, h.cast_count, g.keywords
HAVING 
    h.cast_count > (SELECT AVG(cast_count) FROM HighCastMovies) OR
    EXISTS (SELECT 1 FROM aka_name an WHERE an.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = h.id) AND an.name LIKE '%Smith%')
ORDER BY 
    h.production_year DESC, h.cast_count DESC;

This complex SQL query introduces several advanced concepts:

- **CTEs (Common Table Expressions)**: `RankedMovies`, `HighCastMovies`, and `GenreKeywords` aggregate information about movies and their casts, filtering down to the top cast in each year and linking keywords to their respective movies.
  
- **Window Functions**: `ROW_NUMBER()` enables ranking per year by the count of cast members, contributing to the complexity of the selection criteria.
  
- **COALESCE**: Used to replace NULLs with default values (e.g., 'No Keywords', 'No Companies') ensures the display remains user-friendly.
  
- **String Aggregation**: `STRING_AGG` compiles keywords and company names into single output strings.

- **Subquery and EXISTS Clause**: The query incorporates a subquery to check average cast sizes and an EXISTS clause to find a specific actor's appearance (using a wildcard search for the surname "Smith").

- **HAVING Clause**: Filters results not only based on aggregate cast counts but introduces a semantical corner case with the condition requiring either higher-than-average cast sizes or the presence of particular names in the cast.

- **OUTER JOINs**: These ensure that even if there are no associated companies or keywords, the movie still surfaces in the query result. 

This procedural complexity can help benchmark various performance aspects of SQL queries on the provided schema.
