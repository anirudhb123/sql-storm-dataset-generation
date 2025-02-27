WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
CastAggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(CONCAT_WS(' ', ak.name, ak.surname_pcode), ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ca.actor_count,
        ca.actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastAggregates ca ON mh.movie_id = ca.movie_id
),
QualifiedTitles AS (
    SELECT 
        f.title,
        f.production_year,
        f.actor_count,
        ROW_NUMBER() OVER (PARTITION BY f.production_year ORDER BY f.actor_count DESC) AS rn
    FROM 
        FilteredMovies f
    WHERE 
        f.actor_count IS NOT NULL 
        AND f.production_year > 2000
        AND f.title NOT LIKE '%Unrated%'
)
SELECT 
    qt.title,
    qt.production_year,
    qt.actor_count
FROM 
    QualifiedTitles qt
WHERE 
    qt.rn <= 5
ORDER BY 
    qt.production_year DESC, 
    qt.actor_count DESC;

**Explanation:**

1. **CTE MovieHierarchy**: This recursive Common Table Expression (CTE) builds a hierarchy of movies, where each episode is tracked as belonging to its series based on the `episode_of_id`.

2. **CTE CastAggregates**: This aggregates the cast information, counting the number of actors per movie and concatenating their names into a single string.

3. **CTE FilteredMovies**: This combines the results of the previous CTEs, making sure to keep track of the movie title, year, actor count, and actor names.

4. **CTE QualifiedTitles**: This filters the movies to those produced after 2000 and excludes certain titles. It uses a window function to rank movies based on the actor count per year.

5. **Final Selection**: The final query selects the top 5 movies with the most actors for each production year that meets the criteria, ordering the results by year and actor count.

This query structure showcases a variety of SQL features, including recursive CTEs, window functions, grouping, string aggregations, and filtering with complex predicates.
