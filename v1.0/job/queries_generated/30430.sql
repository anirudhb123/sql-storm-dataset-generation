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
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        MAX(CASE WHEN r.role = 'actor' THEN 1 ELSE 0 END) AS has_actor,
        MAX(CASE WHEN r.role = 'director' THEN 1 ELSE 0 END) AS has_director
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        c.movie_id
),
KeywordAggregation AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mc.num_cast,
    mc.has_actor,
    mc.has_director, 
    COUNT(DISTINCT mk.movie_id) AS linked_movies,
    ka.keywords,
    CASE 
        WHEN mc.num_cast IS NULL THEN 'No Cast Info'
        ELSE 'Has Cast Info'
    END AS cast_info_status,
    CASE 
        WHEN mc.num_cast > 5 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieCast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    KeywordAggregation ka ON mh.movie_id = ka.movie_id
GROUP BY 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    mc.num_cast, 
    mc.has_actor, 
    mc.has_director, 
    ka.keywords
ORDER BY 
    mh.production_year DESC, 
    title_rank;
