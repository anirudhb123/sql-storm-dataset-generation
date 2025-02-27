WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COALESCE(ca.name, 'Unknown') AS actor_name,
        COALESCE(cd.kind, 'N/A') AS role,
        t.id AS movie_id,
        1 AS depth
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ca ON ci.person_id = ca.id
    LEFT JOIN 
        role_type cd ON ci.role_id = cd.id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.title IS NOT NULL 

    UNION ALL

    SELECT 
        mh.movie_title,
        mh.production_year,
        ca.name AS actor_name,
        cd.kind,
        mh.movie_id,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    JOIN 
        aka_name ca ON ci.person_id = ca.id
    JOIN 
        role_type cd ON ci.role_id = cd.id
    WHERE 
        mh.depth < 5 
)

SELECT 
    mh.movie_title,
    mh.production_year,
    mh.actor_name,
    mh.role,
    COUNT(DISTINCT mh.actor_name) OVER (PARTITION BY mh.movie_title ORDER BY mh.production_year) AS distinct_actors_count,
    STRING_AGG(mh.actor_name, ', ') WITHIN GROUP (ORDER BY mh.actor_name) AS actor_list,
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = mh.movie_id 
        AND mi.info LIKE '%Award%'
    ) AS has_award_info
FROM 
    movie_hierarchy mh
WHERE 
    mh.actor_name IS NOT NULL
GROUP BY 
    mh.movie_title, 
    mh.production_year, 
    mh.actor_name, 
    mh.role
HAVING 
    COUNT(mh.actor_name) > 2
ORDER BY 
    mh.production_year DESC,
    mh.movie_title
LIMIT 100;
This SQL query performs a recursive Common Table Expression (CTE) to build a hierarchy of movies and their cast, aggregates actor data, and filters results based on various conditions, including checking for specific award-related information in a subquery and ensuring that actor names are not null. It includes window functions and string aggregations while also demonstrating complex joins and conditions.
