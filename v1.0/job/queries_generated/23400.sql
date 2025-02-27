WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
, ActorRoleCounts AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT ca.movie_id) AS film_count,
        SUM(CASE WHEN cr.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_played
    FROM 
        cast_info ca
    LEFT JOIN 
        role_type cr ON ca.role_id = cr.id
    GROUP BY 
        ca.person_id
)
, TitleKeywordCounts AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
)
SELECT 
    ah.name,
    STRING_AGG(mh.title || ' (' || mh.production_year || ')', ', ') AS movies,
    ak.film_count,
    ak.roles_played,
    tk.keyword_count,
    CASE 
        WHEN ak.roles_played IS NULL THEN 'No Roles'
        WHEN ak.film_count = 0 THEN 'No Films'
        ELSE 'Active Actor'
    END AS actor_status
FROM 
    aka_name ah
LEFT JOIN 
    ActorRoleCounts ak ON ah.person_id = ak.person_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id IN (
        SELECT 
            ca.movie_id 
        FROM 
            cast_info ca
        WHERE 
            ca.person_id = ah.person_id
    )
LEFT JOIN 
    TitleKeywordCounts tk ON mh.movie_id = tk.movie_id
WHERE 
    (mh.depth = 1 OR mh.depth IS NULL) 
    AND (ak.film_count > 0 OR ak.roles_played IS NULL)
GROUP BY 
    ah.name, ak.film_count, ak.roles_played, tk.keyword_count
HAVING 
    COALESCE(ak.roles_played, 0) > 1 
    OR (tk.keyword_count IS NULL AND ak.film_count < 5)
ORDER BY 
    ak.film_count DESC, 
    actor_status DESC;

This SQL query utilizes various advanced constructs, including CTEs, aggregate functions, string expressions, and complex predicates. It provides an overview of actors, their roles and activity levels, linked movies, and keywords, applying intricate logic to filter, group, and sort the resulting data.
