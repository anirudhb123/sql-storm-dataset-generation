WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')  
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1 
    FROM 
        aka_title m 
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
), 
ActorStats AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS num_movies,
        MIN(m.production_year) AS first_movie,
        MAX(m.production_year) AS last_movie,
        COUNT(DISTINCT CASE WHEN m.production_year IS NOT NULL THEN m.id END) AS movies_btw_2000_2010
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
KeywordUsage AS (
    SELECT 
        k.keyword, 
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        keyword k
    LEFT JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    ORDER BY 
        keyword_count DESC
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    as.actor_name,
    as.num_movies,
    as.first_movie,
    as.last_movie,
    ku.keyword,
    ku.keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    (SELECT DISTINCT actor_name, num_movies, first_movie, last_movie FROM ActorStats WHERE first_movie > COALESCE(NULLIF('1990', ''), '1980')) AS as ON mh.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name WHERE name = as.actor_name))
LEFT JOIN 
    KeywordUsage ku ON mh.movie_id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id = (SELECT id FROM keyword WHERE keyword = 'Action'))
WHERE 
    mh.production_year IS NOT NULL 
    AND mh.title IS NOT NULL 
    AND ku.keyword_count > 2
ORDER BY 
    mh.production_year DESC,
    ku.keyword_count DESC
LIMIT 50;
