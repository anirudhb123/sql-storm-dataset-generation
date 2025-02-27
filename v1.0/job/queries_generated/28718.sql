WITH MovieStats AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
        AND t.production_year BETWEEN 1990 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorStats AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT t.id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT t.id) > 5
),
KeywordDistribution AS (
    SELECT 
        mk.keyword,
        COUNT(DISTINCT t.id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        movie_keyword mk
    JOIN 
        title t ON mk.movie_id = t.id
    GROUP BY 
        mk.keyword
    HAVING 
        COUNT(DISTINCT t.id) > 10
)

SELECT 
    ms.movie_title,
    ms.production_year,
    ms.actor_count,
    ms.actors,
    ms.keyword_count,
    ak.actor_name,
    ak.movie_count,
    ak.movies,
    kd.keyword,
    kd.movie_count AS keyword_movie_count,
    kd.movies AS keyword_movies
FROM 
    MovieStats ms
LEFT JOIN 
    ActorStats ak ON ak.movie_count > 5
LEFT JOIN 
    KeywordDistribution kd ON kd.movie_count > 10
ORDER BY 
    ms.production_year DESC, ms.actor_count DESC, ms.keyword_count DESC;
