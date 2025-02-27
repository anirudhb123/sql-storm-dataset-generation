WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
, ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
EligibleActors AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        coalesce(amc.movie_count, 0) AS movie_count
    FROM 
        aka_name ak
    LEFT JOIN 
        ActorMovieCounts amc ON ak.person_id = amc.person_id
)
SELECT 
    em.actor_id,
    em.actor_name,
    SUM(CASE WHEN mh.production_year >= 2000 THEN 1 ELSE 0 END) AS movies_since_2000,
    STRING_AGG(DISTINCT mh.title || ' (' || mh.production_year || ')', ', ') AS movies
FROM 
    EligibleActors em
LEFT JOIN 
    cast_info c ON em.actor_id = c.person_id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
GROUP BY 
    em.actor_id, em.actor_name
HAVING 
    SUM(CASE WHEN mh.production_year >= 2000 THEN 1 ELSE 0 END) > 0
ORDER BY 
    movies_since_2000 DESC, em.actor_name ASC
LIMIT 10;

### Explanation:
1. **Recursive CTE (MovieHierarchy)**: This structure generates a hierarchy of movies linked to each other. It starts with movies identified as the main type and recursively selects linked movies.

2. **ActorMovieCounts CTE**: This gives a count of movies for each actor based on their appearances, which helps in assessing their involvement.

3. **EligibleActors CTE**: This joins the actors' information with their movie counts, allowing for selection of actors with zero and non-zero movie counts.

4. **Main Query**: This combines the EligibleActors and MovieHierarchy to generate a report of actors who appeared in movies released since the year 2000. It computes a summation and concatenation for further analysis.

5. **HAVING Clause**: This ensures only actors who have participated in movies since 2000 are returned.

6. **Sorting and Limits**: Results are sorted by the count of movies from 2000 onwards, then by actor's name, and limited to the top 10 entries to provide a quick overview of prominent actors in that era.

This query is designed to be intricate while incorporating various SQL features, including recursion, aggregates, string manipulation, and NULL handling logic.
