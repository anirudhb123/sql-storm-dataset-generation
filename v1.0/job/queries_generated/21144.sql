WITH RecursiveMovieRoles AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS actor_count,
           STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    WHERE an.name IS NOT NULL
    GROUP BY ci.movie_id
), 
RatedMovies AS (
    SELECT mt.title,
           mt.production_year,
           COALESCE(mi.info, 'No Rating') AS rating_info,
           COALESCE(mk.keyword, 'No Keywords') AS keywords,
           ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) as year_rank
    FROM aka_title mt
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT it.id FROM info_type it WHERE it.info = 'rating')
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    WHERE mt.production_year IS NOT NULL
), 
FilteredMovies AS (
    SELECT mv.title,
           mv.production_year,
           mv.rating_info,
           COALESCE(mr.actor_count, 0) AS total_actors,
           mr.actor_names
    FROM RatedMovies mv
    LEFT JOIN RecursiveMovieRoles mr ON mv.title = mr.movie_id
    WHERE mv.rating_info != 'No Rating'
    AND mv.production_year BETWEEN 2000 AND 2023
)
SELECT DISTINCT fm.title,
                fm.production_year,
                fm.rating_info,
                fm.total_actors,
                fm.actor_names
FROM FilteredMovies fm
WHERE fm.total_actors > 5
UNION ALL
SELECT NULL AS title,
       NULL AS production_year,
       'Total Films with More than 5 Actors' AS rating_info,
       COUNT(fm.total_actors) AS total_actors,
       NULL AS actor_names
FROM FilteredMovies fm
WHERE fm.total_actors > 5
HAVING COUNT(fm.total_actors) > 0
ORDER BY production_year DESC NULLS LAST;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RecursiveMovieRoles`: Counts distinct actors per movie and aggregates their names using `STRING_AGG`.
   - `RatedMovies`: Selects movies with their production year and joins with `movie_info` for ratings and `movie_keyword` for keywords, applying a condition using `COALESCE` to handle NULL values.
   
2. **FilteredMovies**: Combines the results of `RatedMovies` and `RecursiveMovieRoles` ensuring to exclude movies without ratings and limits the years.

3. **Final Select**: Retrieves distinct movies having more than 5 actors, and appends a summary row that counts such movies while handling NULL conditions to create a last row for totals.

4. **Set Operator**: `UNION ALL` is used to merge detailed movie data with a summary count.

5. **NULL Handling**: COALESCE is employed to manage NULLs effectively in columns like ratings and actors, and NULL condition is used creatively in the ORDER BY clause.

This SQL query is designed for performance benchmarking and takes advantage of various SQL functionalities including recursive CTEs, window functions, and set operators, while also handling NULL cases and unexpected semantics uniquely.
