WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, cast_with_roles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
)
SELECT 
    mh.title,
    mh.production_year,
    string_agg(DISTINCT cw.actor_name || ' as ' || COALESCE(cw.role_name, 'Unknown Role'), ', ') AS cast_members,
    mh.level,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era,
    COUNT(DISTINCT cw.actor_name) as unique_actors,
    SUM(CASE WHEN cw.role_name IS NOT NULL THEN 1 ELSE 0 END) AS roles_assigned,
    MAX(cw.total_actors) OVER (PARTITION BY mh.movie_id) AS max_cast_in_movie
FROM movie_hierarchy mh
LEFT JOIN cast_with_roles cw ON mh.movie_id = cw.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COALESCE(MAX(cw.actor_rank), 0) < 5  -- Movies with fewer than 5 actors
ORDER BY 
    mh.level, mh.production_year DESC
LIMIT 50;
