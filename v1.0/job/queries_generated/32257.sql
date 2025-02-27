WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link mc
    JOIN 
        aka_title mt ON mc.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mc.movie_id = mh.movie_id
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT r.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id
),
PopularActors AS (
    SELECT 
        ak.name,
        ac.movie_count,
        ac.roles
    FROM 
        aka_name ak
    JOIN 
        ActorRoleCounts ac ON ak.person_id = ac.person_id
    WHERE 
        ac.movie_count > (SELECT AVG(movie_count) FROM ActorRoleCounts)
)
SELECT 
    mh.title,
    mh.production_year,
    pa.name AS popular_actor,
    COALESCE(NULLIF(pa.roles[1], ''), 'No roles') AS primary_role,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    completion_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    PopularActors pa ON cc.subject_id = pa.person_id
GROUP BY 
    mh.movie_id, pa.name, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, COUNT(DISTINCT mc.company_id) DESC;

This SQL query constructs a recursive CTE to explore a hierarchy of movies released after 2000, counts the number of films associated with actors, aggregates their roles, and connects this with companies involved in the respective movies. It uses multiple advanced SQL features like window functions, outer joins, and array manipulation for complex filtering and aggregation. The final selection gives a summary of movies, their release years, popular actors along with their primary roles, and the count of associated companies.
