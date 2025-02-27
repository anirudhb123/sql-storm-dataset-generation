WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Select top-level movies (not episodes)

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        et.kind_id,
        mh.level + 1
    FROM 
        aka_title et
    INNER JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id -- Join on episode relationship
),
ActorRoleCounts AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MIN(ci.nr_order) AS first_role_order
    FROM 
        cast_info ci
    JOIN 
        MovieHierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        ak.name,
        ar.movie_count,
        ar.first_role_order,
        ROW_NUMBER() OVER (ORDER BY ar.movie_count DESC) AS rank
    FROM 
        aka_name ak
    JOIN 
        ActorRoleCounts ar ON ak.person_id = ar.person_id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    ta.name,
    ta.movie_count,
    ta.first_role_order,
    mh.title AS movie_title,
    mh.production_year,
    CASE 
        WHEN ta.movie_count > 5 THEN 'Frequent Actor'
        WHEN ta.movie_count BETWEEN 3 AND 5 THEN 'Regular Actor'
        ELSE 'Occasional Actor' 
    END AS actor_category
FROM 
    TopActors ta
LEFT JOIN 
    MovieHierarchy mh ON ta.first_role_order = mh.title
WHERE 
    ta.rank <= 10  -- Limit to top 10 actors
ORDER BY 
    ta.movie_count DESC, ta.name;

This query performs several complex operations:
1. It uses a recursive Common Table Expression (CTE) to build a hierarchy of movies and episodes.
2. It counts the number of movies an actor has appeared in and stores the order of their first role.
3. It categorizes actors based on their frequency of roles.
4. It selects details of the top 10 actors, including their name, movie count, first role order, associated movie title, production year, and their actor category.
5. Conditional logic is employed to classify actors as "Frequent", "Regular", or "Occasional".
