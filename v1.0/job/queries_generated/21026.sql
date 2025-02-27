WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        ak.name
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        ac.actor_name,
        mc.company_count,
        mc.companies,
        mk.keyword
    FROM 
        RecursiveMovieCTE m
    LEFT JOIN 
        ActorInfo ac ON m.movie_id = ac.movie_count
    LEFT JOIN 
        MovieCompanies mc ON m.movie_id = mc.movie_id
    WHERE 
        (m.production_year IS NOT NULL AND m.production_year > 2000)
        OR (mk.keyword IS NOT NULL AND mk.keyword != 'No Keywords')
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_name,
    fm.company_count,
    fm.companies,
    fm.keyword,
    CASE
        WHEN fm.company_count IS NULL THEN 'No Companies Listed'
        ELSE fm.company_count::text || ' Companies'
    END AS company_info,
    CASE 
        WHEN fm.keyword IS NULL THEN 'No Keywords'
        ELSE fm.keyword
    END AS keywords_info
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.title;

This SQL query utilizes various advanced SQL constructs:

- **Common Table Expressions (CTEs)**: Used to structure the query into digestible parts, including a recursive CTE for movie details, a CTE for actor stats, and a CTE for movie companies.
- **LEFT JOINs**: Ensures that even if there are no corresponding records in the joined tables, the main records are retained, demonstrating NULL handling.
- **STRING_AGG**: Used to concatenate actors' names and companies for visualization.
- **ROW_NUMBER()**: Provides a way to rank movies by title within their production year.
- **COALESCE**: Deals with NULL values by replacing them with 'No Keywords'.
- **CASE expressions**: Constructs conditional logic to provide clearer information based on the presence or absence of data.
- **WHERE clause with complex predicates**: Filters the final result with both explicit conditions for production year and keywords.
- **Order By Clause**: Sorts results by production year and title for organized output.

This query not only extracts valuable movie-related information but does it in a way that showcases the intricacies of SQL functionality.
