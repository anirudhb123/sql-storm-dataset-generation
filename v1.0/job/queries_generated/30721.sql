WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(NULLIF(m.production_year, 0), 2023) AS production_year,
        0 AS level
    FROM title m
    WHERE m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(NULLIF(m.production_year, 0), 2023) AS production_year,
        mh.level + 1
    FROM title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),

TopMovies AS (
    SELECT 
        mh.movie_title,
        SUM(CASE WHEN c.id IS NOT NULL THEN 1 ELSE 0 END) AS cast_count,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY SUM(CASE WHEN c.id IS NOT NULL THEN 1 ELSE 0 END) DESC) AS year_rank
    FROM MovieHierarchy mh
    LEFT JOIN cast_info c ON c.movie_id = mh.movie_id
    GROUP BY mh.movie_title, mh.production_year
),

NotableMovies AS (
    SELECT 
        tm.movie_title,
        tm.cast_count,
        tm.production_year
    FROM TopMovies tm
    WHERE tm.year_rank <= 10
),

MovieCompaniesInfo AS (
    SELECT 
        t.title AS movie_title,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON cn.id = mc.company_id
    GROUP BY t.title
),

FinalReport AS (
    SELECT 
        n.movie_title,
        n.cast_count,
        n.production_year,
        COALESCE(mci.companies, 'No companies') AS companies_involved
    FROM NotableMovies n
    LEFT JOIN MovieCompaniesInfo mci ON n.movie_title = mci.movie_title
)

SELECT 
    fr.movie_title,
    fr.production_year,
    fr.cast_count,
    fr.companies_involved
FROM FinalReport fr
ORDER BY fr.production_year DESC, fr.cast_count DESC;
This SQL query accomplishes the following:

1. **Recursive Common Table Expression (CTE)**: `MovieHierarchy` constructs a hierarchy of movies based on `episode_of_id` to gather all movies and their respective production years.

2. **Aggregate Functions with CASE**: It calculates the cast count for each movie in `TopMovies`, filtering out movies without a production year.

3. **String Aggregation**: In `MovieCompaniesInfo`, it collects and concatenates the names of companies associated with each movie, grouped by movie title.

4. **Null Handling**: COALESCE is used in multiple places to ensure that no NULL values are displayed in the final report.

5. **Final Selection**: It pulls the needed fields, ordering them by production year and cast count to provide a ranked output of notable movies.

6. **Set Operators (implicitly)**: Utilizes aggregate functions and CTEs that can imply distinct counts while pulling related information from multiple tables. 

This query performs a detailed task of assembling movie data while demonstrating advanced SQL features, including recursive logic, complex joins, window functions, and outer joins.
