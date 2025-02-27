WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
HighProfilityActors AS (
    SELECT 
        movie_id,
        STRING_AGG(actor_name, ', ') AS actors
    FROM 
        ActorRoles
    WHERE 
        actor_rank <= 3
    GROUP BY 
        movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COALESCE(hpa.actors, 'No prominent actors') AS prominent_actors,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(LENGTH(mi.info)) AS avg_info_length,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) > 5 THEN 'High Budget'
        WHEN COUNT(DISTINCT mc.company_id) BETWEEN 3 AND 5 THEN 'Medium Budget'
        ELSE 'Low Budget'
    END AS budget_category
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    HighProfilityActors hpa ON mh.movie_id = hpa.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.title, mh.production_year, hpa.actors
ORDER BY 
    mh.production_year DESC, COUNT(DISTINCT mc.company_id) DESC
LIMIT 10;
