WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
  
    UNION ALL
   
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        ai.person_id,
        ai.movie_id,
        COUNT(DISTINCT ai.role_id) AS role_count,
        ARRAY_AGG(DISTINCT rt.role) AS roles
    FROM 
        cast_info ai
    JOIN 
        role_type rt ON ai.person_role_id = rt.id
    GROUP BY 
        ai.person_id, ai.movie_id
),
TopActors AS (
    SELECT 
        ar.person_id,
        SUM(ar.role_count) AS total_roles
    FROM 
        ActorRoles ar
    GROUP BY 
        ar.person_id
    ORDER BY 
        total_roles DESC
    LIMIT 10
)
SELECT 
    a.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    tah.total_roles,
    CASE 
        WHEN tah.total_roles > 5 THEN 'Highly Active'
        WHEN tah.total_roles BETWEEN 3 AND 5 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS activity_level
FROM 
    TopActors tah
JOIN 
    aka_name a ON tah.person_id = a.person_id
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    mh.level = 1 -- Filter to only top-level movies
ORDER BY 
    tah.total_roles DESC, mh.production_year DESC;

This SQL query does the following:

1. Creates a CTE `MovieHierarchy` to identify the hierarchy of movies linked together.
2. Creates another CTE `ActorRoles` to aggregate data about actor roles in movies.
3. Identifies the top 10 most active actors in terms of roles played across movies in the `TopActors` CTE.
4. Finally, it combines the information to display the actor's name, the movie's title and year, their total roles, and their activity level (categorized based on the total number of roles). 

This involves recursive CTEs, aggregates, string and NULL logic, and joins that can reflect intricate relationships among the tables.
