WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        NULL::integer AS parent_id,
        1 AS level
    FROM 
        title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        mh.movie_id AS parent_id,
        mh.level + 1 AS level
    FROM 
        title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),

CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),

MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM 
        movie_keyword mt
    JOIN 
        keyword kt ON mt.keyword_id = kt.id
    GROUP BY 
        mt.movie_id
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(cs.cast_count, 0) AS cast_count,
        COALESCE(cs.cast_names, 'No Cast') AS cast_names,
        COALESCE(mg.genres, 'No Genres') AS genres,
        mh.level
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastStatistics cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        MovieGenres mg ON mh.movie_id = mg.movie_id
)

SELECT 
    md.title,
    md.cast_count,
    md.cast_names,
    md.genres,
    md.level,
    CASE 
        WHEN md.level = 1 THEN 'Top Level Movie'
        WHEN md.level > 1 AND md.level <= 3 THEN 'Episode'
        ELSE 'Subepisode'
    END AS category
FROM 
    MovieDetails md
WHERE 
    md.cast_count > 0 OR md.genres <> 'No Genres'
ORDER BY 
    md.level, md.title;
This SQL query involves:

1. A recursive CTE (`MovieHierarchy`) to build a hierarchy of movies and series, allowing you to understand the relationships between movies and their episodes.
2. A CTE (`CastStatistics`) that aggregates the cast information for each movie, counting the number of actors and concatenating their names into a single string.
3. Another CTE (`MovieGenres`) that collects genres (keywords) associated with movies.
4. A final CTE (`MovieDetails`) that combines the hierarchy, cast statistics, and genres.
5. A select statement that categorizes movies based on their hierarchy level and filters results based on the presence of casts or genres.
6. The use of string aggregation and NULL handling to ensure meaningful outputs.
