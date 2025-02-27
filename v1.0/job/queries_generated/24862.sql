WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
),
GenreStats AS (
    SELECT 
        kt.keyword AS genre_keyword,
        COUNT(DISTINCT mh.movie_id) AS movie_count,
        AVG(mh.depth) AS avg_depth
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        kt.keyword
),
ActorStats AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(COALESCE(ct.id, 0)) AS avg_role_id
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        role_type ct ON ci.role_id = ct.id
    GROUP BY 
        ak.name
),
FilteredMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        gs.genre_keyword,
        as.name AS actor_name,
        AS.movie_count AS actor_movies
    FROM 
        MovieHierarchy mh
    JOIN 
        GenreStats gs ON mh.title LIKE '%' || gs.genre_keyword || '%'
    JOIN 
        ActorStats as ON mh.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = (SELECT person_id FROM aka_name WHERE name = as.name))
),
RankedMovies AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY genre_keyword ORDER BY movie_count DESC, production_year DESC) AS rank
    FROM 
        FilteredMovies
)
SELECT 
    title,
    production_year,
    genre_keyword,
    actor_name,
    actor_movies
FROM 
    RankedMovies
WHERE 
    rank <= 5
    AND production_year >= (SELECT MAX(production_year) - 10 FROM aka_title)
ORDER BY 
    genre_keyword, movie_count DESC;

This SQL query performs an elaborate analysis of movies, their genres, and actors involved. It builds a recursive common table expression to handle potentially linked movies, aggregates statistics for genres and actors, and ranks movies based on actor involvement and genre keywords. It involves outer joins, subqueries, CTEs, window functions, and carefully handles NULL logic while filtering for fairly recent films, showcasing a complex interaction of relational database features.
