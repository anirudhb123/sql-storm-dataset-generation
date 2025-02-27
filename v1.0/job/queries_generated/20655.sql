WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
),

ActorsWithMovies AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT at.title, ', ') AS movies,
        AVG(m.production_year) AS avg_year
    FROM 
        aka_name a
    LEFT JOIN cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN aka_title at ON ci.movie_id = at.id
    LEFT JOIN MovieHierarchy m ON at.id = m.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),

MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
    GROUP BY 
        m.id
)

SELECT 
    awm.actor_name,
    awm.movie_count,
    awm.movies,
    mw.keywords,
    (CASE 
        WHEN awm.avg_year < 2010 THEN 'Older Movies'
        WHEN awm.avg_year BETWEEN 2010 AND 2015 THEN 'Modern Movies'
        ELSE 'Recent Movies'
    END) AS movie_category
FROM 
    ActorsWithMovies awm
LEFT JOIN MovieKeywords mw ON awm.movie_count = (SELECT MAX(movie_count) FROM ActorsWithMovies)
ORDER BY 
    awm.movie_count DESC, 
    awm.actor_name ASC
LIMIT 10;
