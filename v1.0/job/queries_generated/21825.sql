WITH recursive movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(t1.title, 'N/A') AS parent_title,
        t1.id AS parent_id,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        aka_title t1 ON m.episode_of_id = t1.id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(t2.title, 'N/A') AS parent_title,
        t2.id AS parent_id,
        level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
    LEFT JOIN 
        aka_title t2 ON mh.parent_id = t2.id
),

artificial_join AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (role: ', r.role, ')'), ', ') AS actors_details
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),

movies_with_actor_count AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        ac.actors_details
    FROM 
        movie_hierarchy m
    LEFT JOIN 
        artificial_join ac ON m.movie_id = ac.movie_id
)

SELECT 
    mw.movie_title,
    mw.production_year,
    mw.actor_count,
    mw.actors_details,
    CASE 
        WHEN mw.actor_count = 0 THEN 'No Cast'
        WHEN mw.actor_count <= 3 THEN 'Small Cast'
        WHEN mw.actor_count <= 10 THEN 'Moderate Cast'
        ELSE 'Large Cast'
    END AS cast_size_category,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    movies_with_actor_count mw
LEFT JOIN 
    movie_keyword mk ON mw.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mw.production_year BETWEEN 2000 AND 2023 
    AND mw.actor_count IS NOT NULL 
GROUP BY 
    mw.movie_title, mw.production_year, mw.actor_count, mw.actors_details
ORDER BY 
    mw.production_year DESC, mw.actor_count DESC;

This SQL query explores several sophisticated constructs:

1. **Common Table Expressions (CTEs)**: The query uses multiple CTEs to build a hierarchical view of movies, their relationships, and the actor details.

2. **Recursive CTE**: The `movie_hierarchy` CTE is recursive, generating a hierarchy of movies (specifically for series) by connecting episodes to their parent titles.

3. **String Aggregation**: It uses `STRING_AGG` to concatenate actor names along with their roles.

4. **Aggregation and Grouping**: The final selection aggregates data to categorize the movies based on the number of actors.

5. **Conditional Logic**: The `CASE` statement categorizes movies based on the size of their cast.

6. **Left Joins**: The query uses various `LEFT JOIN` operations to handle potential sparsity in the relationships and allows for the inclusion of movies without actors or keywords.

7. **Complex Predicates**: The `WHERE` clause uses a range to filter movies based on their production years.

8. **Distinct Count**: The use of `COUNT(DISTINCT...)` showcases an understanding of potentially duplicated keyword associations.

This query comprises several intricate SQL concepts, making it suitable for performance benchmarking on a combined dataset.
