WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        '' AS parent_title
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level,
        mh.title AS parent_title
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CastRoles AS (
    SELECT 
        ci.person_id,
        r.role AS role,
        COUNT(*) AS roles_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id, r.role
),
TopActors AS (
    SELECT 
        person_id,
        role,
        roles_count,
        RANK() OVER (PARTITION BY role ORDER BY roles_count DESC) AS role_rank
    FROM 
        CastRoles
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ARRAY_AGG(DISTINCT ka.name) AS actor_names,
        (SELECT COUNT(*) 
         FROM movie_keyword mk 
         WHERE mk.movie_id = mh.movie_id) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mh.movie_id
    LEFT JOIN 
        aka_name ka ON ka.person_id = ci.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    md.keyword_count,
    ta.role,
    ta.roles_count
FROM 
    MovieDetails md
LEFT JOIN 
    TopActors ta ON ta.person_id = ANY(md.actor_names)
WHERE 
    md.production_year BETWEEN 2000 AND 2023
    AND ta.roles_count IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    ta.roles_count DESC, 
    md.title;

This query performs the following tasks:

1. Creates a recursive Common Table Expression (CTE) `MovieHierarchy` that builds a hierarchy of movies and their episodes.

2. Builds another CTE `CastRoles` that counts the number of roles each actor has played.

3. Defines a `TopActors` CTE where actors are ranked based on their number of roles, grouped by the type of role.

4. Finally, in the `MovieDetails` CTE, it gathers detailed movie information, including the names of the actors involved and the count of keywords associated.

5. The final SELECT combines everything, filtering on a specific production year range, joining on actors from `TopActors`, and ordering the results by production year, role count, and title. 

This structure provides a detailed view of movies, their associations, and performance metrics, suitable for benchmarking complex queries against a well-structured relational database.
