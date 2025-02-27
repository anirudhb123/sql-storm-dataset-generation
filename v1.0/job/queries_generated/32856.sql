WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.movie_id,
        ca.person_id AS actor_id,
        na.name AS actor_name,
        0 AS level
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS na ON c.person_id = na.person_id
    JOIN 
        aka_title AS at ON c.movie_id = at.movie_id
    WHERE 
        at.production_year IS NOT NULL
  
    UNION ALL
  
    SELECT 
        mh.movie_id,
        ca.person_id,
        na.name,
        ah.level + 1
    FROM 
        ActorHierarchy AS ah
    JOIN 
        movie_link AS ml ON ah.movie_id = ml.movie_id
    JOIN 
        cast_info AS ca ON ml.linked_movie_id = ca.movie_id 
    JOIN 
        aka_name AS na ON ca.person_id = na.person_id
    WHERE 
        ah.level < 10  -- Limit depth of recursion
),
RankedActors AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(movie_id) DESC) AS actor_rank
    FROM 
        ActorHierarchy
    GROUP BY 
        actor_id, actor_name
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
)
SELECT 
    m.movie_title,
    a.actor_name,
    a.movie_count,
    mwk.keywords,
    CASE 
        WHEN a.movie_count > 5 THEN 'Prolific Actor' 
        ELSE 'Emerging Actor' 
    END AS actor_status,
    COALESCE(NULLIF(mwk.keywords[1], ''), 'No Keywords') AS primary_keyword
FROM 
    RankedActors AS a
JOIN 
    MoviesWithKeywords AS mwk ON a.actor_id = ANY(SELECT person_id FROM cast_info WHERE movie_id IN (SELECT movie_id FROM ActorHierarchy))
WHERE 
    a.actor_rank <= 100  -- Fetch top 100 ranked actors
ORDER BY 
    a.movie_count DESC, a.actor_name;

This SQL query performs several interesting operations:

1. **Recursive CTE (`ActorHierarchy`)**: It builds a hierarchy of actors based on movies they have worked on, allowing for a maximum depth of recursion to avoid excessive complexity.

2. **Aggregated Data and Ranking**: The second CTE (`RankedActors`) groups the results to count the number of movies per actor and assigns a rank based on this count.

3. **Genres and Keywords with Aggregation**: The third CTE (`MoviesWithKeywords`) aggregates movie keywords, helping to understand what each movie is about.

4. **Final Selection**: The final SELECT statement combines data from the actors and their associated movies, including actor-related statuses based on their movie count and handling potential NULL values for keywords.

5. **Use of Case Logic**: It provides a classification of actors based on their involvement in movies ("Prolific Actor" or "Emerging Actor").

The query demonstrates the use of advanced SQL features effectively and is designed for performance benchmarking of complex queries within the defined schema.
