WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.id AS original_movie_id
    FROM aka_title mt
    WHERE mt.production_year >= 1990

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1,
        mh.original_movie_id
    FROM movie_link ml
    JOIN aka_title lt ON ml.linked_movie_id = lt.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieConsideration AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COALESCE(CAST(SUM(mcg.note IS NOT NULL) AS INTEGER), 0) AS note_count
    FROM MovieHierarchy mh
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_info minfo ON mh.movie_id = minfo.movie_id
    WHERE cn.country_code IS NULL OR cn.country_code <> 'USA'
    GROUP BY mh.movie_id, mh.title, mh.production_year, mh.level
),
RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY level ORDER BY note_count DESC, production_year DESC) AS rn
    FROM MovieConsideration
    WHERE note_count > 0
),
FinalMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(cn.name, 'Unknown') AS company_name,
        rm.level
    FROM RankedMovies rm
    LEFT JOIN movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE rm.rn <= 10
)
SELECT 
    f.title,
    f.production_year,
    f.company_name,
    f.level
FROM FinalMovies f
ORDER BY f.level, f.production_year DESC;

This query does the following:
1. **Recursive CTE**: `MovieHierarchy` builds a hierarchy of movies based on their related movies from the `movie_link` table, starting from movies produced after 1990.
2. **Consideration CTE**: `MovieConsideration` calculates the total number of notes associated with each movie where the company is either null (no company) or from a different country than 'USA'.
3. **RankedMovies CTE**: This part ranks the movies at each level based on the note count and production year.
4. **Final Selection**: `FinalMovies` retrieves the top 10 movies (based on rank and excluding those with zero notes) along with their year of production and company name.
5. **Final Output**: It selects and orders the final results for output. 

This query makes use of outer joins, window functions, CTEs, and thorough filtering, showcasing a blend of advanced SQL techniques while being focused on the benchmarking of movies.
