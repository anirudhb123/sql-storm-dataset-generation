WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        lt.title AS movie_title,
        lt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
AggregatedMovies AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        m.movie_id, m.movie_title, m.production_year
),
PopularMovies AS (
    SELECT 
        am.movie_id,
        am.movie_title,
        am.production_year,
        am.cast_count,
        am.actor_names,
        RANK() OVER (PARTITION BY am.production_year ORDER BY am.cast_count DESC) AS rank_within_year
    FROM 
        AggregatedMovies am
)
SELECT 
    pm.movie_title,
    pm.production_year,
    pm.cast_count,
    pm.actor_names
FROM 
    PopularMovies pm
WHERE 
    pm.rank_within_year <= 5
ORDER BY 
    pm.production_year DESC, 
    pm.cast_count DESC;

This SQL query demonstrates an elaborate use of several SQL constructs. 

1. **Recursive CTE**: The `MovieHierarchy` CTE recursively constructs a hierarchy of movies linked by their relationships.
2. **Aggregate Functions**: The `AggregatedMovies` CTE aggregates movies, counting unique cast members (`cast_count`) and concatenating their names (`actor_names`) using `STRING_AGG()`.
3. **Window Functions**: The `RANK()` function in the `PopularMovies` CTE ranks movies based on the number of cast members for each production year.
4. **Outer Joins**: LEFT JOINS are used to include all movies even if they don’t have associated cast entries.
5. **Final Selection**: The final selection retrieves the top 5 movies each year based on cast size, ordered by year and then by cast count. 

This approach allows for comprehensive insights into the movie database.
