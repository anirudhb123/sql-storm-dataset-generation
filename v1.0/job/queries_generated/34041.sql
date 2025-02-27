WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1  -- Assuming 1 represents 'movie'

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
ActorRatings AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        AVG(r.rating) AS avg_rating
    FROM 
        cast_info a
    JOIN 
        aka_name ak ON a.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON a.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT movie_id, CAST(info AS DECIMAL) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) r ON a.movie_id = r.movie_id
    GROUP BY 
        a.id, ak.name
),
PopularMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        MovieHierarchy mh
    JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5  -- Movies with more than 5 actors
),
FinalResults AS (
    SELECT 
        pm.title AS movie_title,
        pm.production_year,
        pm.actor_count,
        ar.actor_name,
        ar.avg_rating
    FROM 
        PopularMovies pm
    LEFT JOIN 
        ActorRatings ar ON pm.movie_id = ar.actor_id
)
SELECT 
    movie_title,
    production_year,
    actor_count,
    COALESCE(AVG(avg_rating), 0) AS average_actor_rating
FROM 
    FinalResults
GROUP BY 
    movie_title, production_year, actor_count
ORDER BY 
    actor_count DESC, production_year DESC
LIMIT 10;
