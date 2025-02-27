WITH RECURSIVE 
    MovieHierarchy AS (
        SELECT 
            mt.id AS movie_id,
            mt.title,
            mt.production_year,
            1 AS level
        FROM 
            aka_title mt 
        WHERE 
            mt.production_year >= 2000
        
        UNION ALL 

        SELECT 
            ml.linked_movie_id AS movie_id,
            at.title,
            at.production_year,
            mh.level + 1 AS level
        FROM 
            MovieHierarchy mh
        JOIN 
            movie_link ml ON mh.movie_id = ml.movie_id
        JOIN 
            aka_title at ON ml.linked_movie_id = at.id
        WHERE 
            mh.level < 4
    ),
    ActorRoles AS (
        SELECT 
            ci.movie_id,
            ak.name AS actor_name,
            rt.role,
            ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_rank
        FROM 
            cast_info ci
        JOIN 
            aka_name ak ON ci.person_id = ak.person_id
        JOIN 
            role_type rt ON ci.role_id = rt.id
    ),
    MovieInfoAggregated AS (
        SELECT 
            mh.movie_id,
            mh.title,
            STRING_AGG(DISTINCT ar.actor_name, ', ') AS actors,
            COUNT(DISTINCT ar.actor_name) AS actor_count,
            AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length
        FROM 
            MovieHierarchy mh
        LEFT JOIN 
            ActorRoles ar ON mh.movie_id = ar.movie_id
        LEFT JOIN 
            movie_info mi ON mh.movie_id = mi.movie_id
        GROUP BY 
            mh.movie_id, mh.title
    )
SELECT 
    m.title AS movie_title,
    m.production_year,
    m.actor_count,
    m.avg_info_length,
    CASE 
        WHEN m.actor_count > 5 THEN 'Ensemble Cast'
        WHEN m.actor_count BETWEEN 3 AND 5 THEN 'Small Cast'
        ELSE 'Minimal Cast'
    END AS cast_category,
    COALESCE(comp.name, 'Unknown Company') AS production_company
FROM 
    MovieInfoAggregated m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name comp ON mc.company_id = comp.id
WHERE 
    m.avg_info_length > 50
ORDER BY 
    m.avg_info_length DESC, 
    m.actor_count DESC
LIMIT 10;
