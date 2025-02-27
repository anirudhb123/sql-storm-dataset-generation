WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        NULL::integer AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    UNION ALL
    SELECT 
        m.id, 
        m.title, 
        m.production_year, 
        m.episode_of_id AS parent_id
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
), 
ActorDetails AS (
    SELECT 
        ka.name AS actor_name,
        ka.id AS actor_id,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name ka ON c.person_id = ka.person_id
    WHERE 
        ka.name IS NOT NULL
), 
MovieKeywords AS (
    SELECT 
        m.id AS movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(md.keywords, '<No Keywords>') AS keywords,
    COUNT(DISTINCT ad.actor_id) AS total_actors,
    AVG(ad.role_order) AS avg_role_order
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieKeywords md ON mh.movie_id = md.movie_id
LEFT JOIN 
    ActorDetails ad ON mh.movie_id = ad.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, md.keywords
ORDER BY 
    mh.production_year DESC, total_actors DESC
LIMIT 10;
