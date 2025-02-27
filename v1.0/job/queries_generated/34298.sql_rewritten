WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        ml.movie_id AS root_movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related to')
    
    UNION ALL

    SELECT 
        mh.root_movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related to')
),

AggregatedMovies AS (
    
    SELECT 
        mh.root_movie_id,
        COUNT(mh.linked_movie_id) AS related_movies_count,
        MAX(mh.level) AS max_related_level
    FROM 
        MovieHierarchy mh
    GROUP BY 
        mh.root_movie_id
),

MoviesWithInfo AS (
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(am.related_movies_count, 0) AS related_movies_count,
        COALESCE(am.max_related_level, 0) AS max_related_level
    FROM 
        title t
    LEFT JOIN 
        AggregatedMovies am ON t.id = am.root_movie_id
)


SELECT 
    mw.movie_id, 
    mw.title, 
    mw.production_year,
    mw.related_movies_count,
    mw.max_related_level,
    ak.name AS actor_name,
    ci.nr_order,
    rk.role
FROM 
    MoviesWithInfo mw
LEFT JOIN 
    cast_info ci ON mw.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    role_type rk ON ci.role_id = rk.id
WHERE 
    mw.related_movies_count > 5 
    AND mw.production_year BETWEEN 2000 AND 2020 
ORDER BY 
    mw.related_movies_count DESC,
    mw.max_related_level ASC;