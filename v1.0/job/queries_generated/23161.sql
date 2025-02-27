WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COALESCE(mk.keyword, 'Unknown') AS movie_keyword,
        COALESCE(comp.name, 'Independent') AS company_name,
        (SELECT COUNT(*) 
         FROM movie_companies mc 
         WHERE mc.movie_id = t.id AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')) AS distributor_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name comp ON mc.company_id = comp.id
    WHERE 
        t.production_year IS NOT NULL
), FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        movie_keyword,
        company_name,
        distributor_count,
        CASE 
            WHEN distributor_count > 0 THEN 'Has Distributor'
            ELSE 'No Distributor'
        END AS distributor_info
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 10 AND production_year > 2000
), AggregateMovies AS (
    SELECT 
        company_name,
        COUNT(*) AS total_movies,
        STRING_AGG(DISTINCT title, ', ') AS all_movies
    FROM 
        FilteredMovies
    GROUP BY 
        company_name
)

SELECT 
    COALESCE(fm.company_name, 'Unknown Company') AS Company,
    fm.total_movies,
    fm.all_movies,
    COALESCE((SELECT AVG(distributor_count)::FLOAT 
               FROM FilteredMovies fmp 
               WHERE fmp.company_name IS NOT NULL), 0) AS avg_distributor_count,
    (SELECT 
        MAX(production_year)
     FROM 
        FilteredMovies fm2) AS latest_year
FROM 
    AggregateMovies fm
LEFT JOIN 
    (SELECT company_name, SUM(CASE WHEN total_movies > 5 THEN 1 ELSE 0 END) AS prolific_companies 
     FROM AggregateMovies 
     GROUP BY company_name) as prolific 
ON 
    fm.company_name = prolific.company_name
WHERE 
    COALESCE(prolific.prolific_companies, 0) > 0
ORDER BY 
    total_movies DESC;

This SQL query introduces several interesting features:
- **CTEs (Common Table Expressions)** for breaking down the query process.
- **Window Functions** are used to rank movies by production year.
- **Left Joins** to ensure all movies are included, even if they lack associated keywords or companies.
- **Correlated Subqueries** to gather the count of distributors for each movie.
- **COALESCE** is used throughout to handle NULL values and substitute defaults.
- **STRING_AGG** to concatenate movie titles for each company.
- **HAVING and GROUP BY** to filter aggregated results.
- **Complex case statements** to modify output based on conditions.
- **Unusual SQL semantics**, such as evaluating AVG on a sub-select, showcasing its operational complexity.
- **Final selection with order** making use of the aggregate results and derived table for filtered prolific companies.
