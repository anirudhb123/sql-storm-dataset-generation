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
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
),
TopMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title,
        mh.production_year, 
        ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.depth = 1
),
ActorRoles AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        STRING_AGG(DISTINCT rt.role) AS roles
    FROM 
        cast_info ca
    LEFT JOIN 
        role_type rt ON ca.role_id = rt.id
    GROUP BY 
        ca.person_id, ca.movie_id
),
MovieStats AS (
    SELECT 
        mt.title,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        AVG(COALESCE(mvi.info, 0)) AS avg_info_value
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ca ON mt.id = ca.movie_id
    LEFT JOIN 
        movie_info mvi ON mt.id = mvi.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
    GROUP BY 
        mt.title
),
TopActors AS (
    SELECT 
        an.name AS actor_name,
        COUNT(DISTINCT ar.movie_id) AS movies_count
    FROM 
        aka_name an
    JOIN 
        ActorRoles ar ON an.person_id = ar.person_id
    GROUP BY 
        an.name
    HAVING 
        COUNT(DISTINCT ar.movie_id) > 5
)
SELECT 
    tm.title AS top_movie,
    ma.actor_name,
    ms.actor_count,
    ms.avg_info_value,
    ma.movies_count AS actor_movies_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieStats ms ON tm.title = ms.title
LEFT JOIN 
    TopActors ma ON ma.actor_movies_count > 5
WHERE 
    ms.actor_count IS NOT NULL
ORDER BY 
    ms.avg_info_value DESC, 
    ma.movies_count DESC
LIMIT 10
OFFSET 5;
