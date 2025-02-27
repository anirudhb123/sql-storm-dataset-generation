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
        mt.production_year > 1990  -- Base case for recent movies
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.production_year) AS average_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_movies DESC;
    
-- Bonus: Analyze the top 10 actors with respect to their participation in movies including related keywords.
WITH ActorParticipation AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS participation_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
)
SELECT 
    ap.actor_name,
    ap.participation_count,
    ROW_NUMBER() OVER (ORDER BY ap.participation_count DESC) AS rank
FROM 
    ActorParticipation ap
WHERE 
    ap.participation_count IS NOT NULL
LIMIT 10;

This query begins with a recursive Common Table Expression (CTE) that builds a hierarchy of movies linked together through the `movie_link` table, starting from movies produced after 1990. The first part of the query counts total movies and calculates the average production year for actors (found in the `cast_info` table) who played more than five distinct movies, while also aggregating associated keywords from the `keyword` and `movie_keyword` tables. In the second part, we identify the top 10 actors based on their participation count across all movies, utilizing window functions to assign a rank to these actors.
