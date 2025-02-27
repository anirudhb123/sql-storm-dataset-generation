WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS title, 
        ARRAY[mt.title] AS title_path,
        1 AS depth
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year IS NOT NULL -- filter out titles without a production year
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        lt.title AS title,
        mh.title_path || lt.title AS title_path,
        mh.depth + 1
    FROM 
        movie_link ml 
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id 
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') OVER (PARTITION BY c.movie_id) AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c 
    JOIN 
        aka_name a ON c.person_id = a.person_id 
)
, rich_movie_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(mc.actor_count, 0) AS total_actors,
        mh.title_path,
        mh.depth,
        CASE 
            WHEN mh.depth > 2 THEN 'Deep Hierarchy' 
            ELSE 'Shallow Hierarchy' 
        END AS hierarchy_type
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_cast mc ON mh.movie_id = mc.movie_id
)
SELECT 
    rmi.title,
    rmi.total_actors,
    rmi.hierarchy_type,
    (SELECT COUNT(DISTINCT title) FROM aka_title WHERE production_year < 2000) AS classic_movies_count,
    CASE 
        WHEN rmi.total_actors > 10 THEN 'Ensemble' 
        WHEN rmi.total_actors > 0 THEN 'Solo' 
        ELSE 'No Actors' 
    END AS actor_status,
    (SELECT STRING_AGG(DISTINCT kw.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword kw ON mk.keyword_id = kw.id 
     WHERE mk.movie_id = rmi.movie_id) AS keywords
FROM 
    rich_movie_info rmi
WHERE 
    rmi.total_actors > 0 
ORDER BY 
    rmi.total_actors DESC, rmi.title;

