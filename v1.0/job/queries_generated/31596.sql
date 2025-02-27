WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        at.title,
        at.production_year,
        COUNT(c.id) AS num_roles,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY at.production_year DESC) AS latest_role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title at ON c.movie_id = at.movie_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        a.name, at.title, at.production_year
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS movies_per_year,
        ROW_NUMBER() OVER (ORDER BY mh.production_year DESC) AS movie_rank
    FROM 
        MovieHierarchy mh
)
SELECT 
    a.actor_name,
    am.title AS movie_title,
    am.production_year,
    rm.movies_per_year,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = am.title AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')) AS rating_count,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM company_name cn 
     JOIN movie_companies mc ON cn.id = mc.company_id 
     WHERE mc.movie_id = am.title) AS production_companies
FROM 
    ActorMovies am
JOIN 
    RankedMovies rm ON am.title = rm.title AND am.production_year = rm.production_year
WHERE 
    am.latest_role = 1
ORDER BY 
    rm.movie_rank, a.actor_name;
