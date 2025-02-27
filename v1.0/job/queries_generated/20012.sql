WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopCastMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(CT.kind, 'Unknown') AS company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.title = (SELECT title from aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_type CT ON mc.company_type_id = CT.id
    WHERE 
        rm.rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS movie_id,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    tcm.title,
    tcm.production_year,
    tcm.cast_count,
    tcm.company_type,
    COALESCE(mw.keywords, 'No keywords assigned') AS keywords
FROM 
    TopCastMovies tcm
LEFT JOIN 
    MoviesWithKeywords mw ON tcm.title = (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE phrase LIKE '%Action%')))
WHERE 
    tcm.company_type IS NOT NULL
    AND tcm.cast_count > 1
    AND (tcm.production_year BETWEEN 1990 AND 2023 OR tcm.production_year IS NULL)
ORDER BY 
    tcm.production_year DESC, tcm.cast_count DESC
LIMIT 100;

This query performs several operations:

1. **CTEs (Common Table Expressions)** to first rank movies by their cast size and retrieve the top 5 based on year.
2. **LEFT JOINs** to connect necessary tables and gather additional information about the cast and companies associated with the movies.
3. A subquery in the `JOIN` clause to retrieve movies associated with a specific keyword, demonstrating the use of correlated subqueries.
4. **NULL logic** with `COALESCE` to handle cases where no keywords or company types are available.
5. **GROUP_CONCAT** (this may require modification to match your SQL dialect, such as using `STRING_AGG` or a similar function) to aggregate keywords for each movie.
6. Complicated `WHERE` predicates, combining conditions based on production year and presence of keywords.

This structure ensures representational complexity while also providing a performance testing framework, allowing evaluation on joins, groupings, rank operations, subqueries, and handling of NULL values, showcasing nuanced SQL skills.
