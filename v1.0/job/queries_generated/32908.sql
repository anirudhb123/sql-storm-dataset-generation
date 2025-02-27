WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id AS movie_id,
        title,
        production_year,
        episode_of_id,
        1 AS level
    FROM 
        aka_title
    WHERE 
        production_year >= 2000

    UNION ALL

    SELECT 
        titles.id AS movie_id,
        titles.title,
        titles.production_year,
        titles.episode_of_id,
        hierarchy.level + 1 AS level
    FROM 
        aka_title titles
    INNER JOIN 
        MovieHierarchy hierarchy ON titles.episode_of_id = hierarchy.movie_id
),
ActorRoles AS (
    SELECT 
        c.person_id, 
        c.movie_id, 
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order IS NOT NULL
),
ActorsWithMovies AS (
    SELECT 
        a.person_id,
        a.movie_id,
        a.role,
        COALESCE(mh.production_year, 'Unknown') AS production_year,
        mh.title
    FROM 
        ActorRoles a
    LEFT JOIN 
        MovieHierarchy mh ON a.movie_id = mh.movie_id
)
SELECT 
    ak.id AS actor_id,
    ak.name AS actor_name,
    COUNT(DISTINCT awm.movie_id) AS movie_count,
    STRING_AGG(DISTINCT awm.title || ' (' || awm.production_year || ')', ', ') AS movie_list,
    MAX(CASE WHEN awm.production_year IS NULL THEN 'No Year' ELSE awm.production_year END) AS last_known_year,
    AVG(CASE WHEN awm.production_year IS NOT NULL THEN awm.production_year ELSE NULL END) AS avg_production_year,
    MIN(awm.production_year) FILTER (WHERE awm.production_year IS NOT NULL) AS first_known_year
FROM 
    aka_name ak
LEFT JOIN 
    ActorsWithMovies awm ON ak.person_id = awm.person_id
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(DISTINCT awm.movie_id) > 3
ORDER BY 
    movie_count DESC, actor_name;
