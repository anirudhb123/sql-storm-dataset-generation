WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Selecting only movies

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 5 -- Limiting hierarchy depth to 5
),

ActorMovies AS (
    SELECT 
        a.person_id,
        a.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY mt.production_year DESC) AS rn
    FROM 
        cast_info a
    JOIN 
        aka_title mt ON a.movie_id = mt.id
),

ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        am.movie_id,
        mh.title AS movie_title,
        mh.production_year,
        a.percentage
    FROM 
        ActorMovies am
    JOIN 
        aka_name ak ON am.person_id = ak.person_id
    JOIN 
        MovieHierarchy mh ON am.movie_id = mh.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT person_id) * 100.0 / NULLIF(COUNT(*), 0) AS percentage
        FROM 
            cast_info
        GROUP BY 
            movie_id
    ) a ON am.movie_id = a.movie_id
    WHERE 
        am.rn = 1
)

SELECT 
    ad.actor_name,
    STRING_AGG(DISTINCT ad.movie_title, ', ') AS movies,
    COUNT(DISTINCT ad.movie_id) AS total_movies,
    AVG(ad.production_year) AS avg_production_year,
    MAX(ad.percentage) AS avg_percentage_of_actors,
    COUNT(DISTINCT mh.movie_id) AS linked_movies
FROM 
    ActorDetails ad
JOIN 
    MovieHierarchy mh ON ad.movie_id = mh.movie_id
WHERE 
    ad.movie_title IS NOT NULL
GROUP BY 
    ad.actor_name
HAVING 
    COUNT(DISTINCT ad.movie_id) > 1
ORDER BY 
    total_movies DESC
LIMIT 10;
