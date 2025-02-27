WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::text AS parent_title
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Select movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        m.level + 1,
        m.title AS parent_title
    FROM 
        MovieCTE m
    JOIN 
        movie_link ml ON ml.movie_id = m.movie_id
    JOIN 
        aka_title mt ON mt.id = ml.linked_movie_id
    WHERE 
        m.level < 3 -- Limit to 3 levels of movie linking
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS total_movies,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT cc.movie_id) DESC) AS rn
    FROM 
        aka_name ak
    JOIN 
        cast_info cc ON cc.person_id = ak.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = cc.movie_id
    GROUP BY 
        ak.id
    HAVING 
        COUNT(DISTINCT cc.movie_id) >= 5  -- Actors with at least 5 movies
),
MovieStats AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(a.actor_name, 'Unknown') AS lead_actor,
        COALESCE(a.total_movies, 0) AS actor_movie_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        MovieCTE m
    LEFT JOIN 
        ActorInfo a ON a.rn = 1  -- Joining to get the lead actor info
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year, a.actor_name, a.total_movies
)
SELECT 
    ms.title,
    ms.production_year,
    ms.lead_actor,
    ms.actor_movie_count,
    ms.keyword_count,
    CASE 
        WHEN ms.keyword_count > 10 THEN 'Highly Tagged'
        WHEN ms.keyword_count BETWEEN 5 AND 10 THEN 'Moderately Tagged'
        ELSE 'Less Tagged'
    END AS tagging_status
FROM 
    MovieStats ms
WHERE 
    ms.production_year = (SELECT MAX(production_year) FROM movie_info) -- Movies from the latest production year
ORDER BY 
    ms.keyword_count DESC, 
    ms.production_year DESC;
