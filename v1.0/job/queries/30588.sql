WITH RECURSIVE MovieHierarchy AS (
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
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),
CastAggregation AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN ci.role_id IN (SELECT id FROM role_type WHERE role = 'Actor') THEN ci.person_id END) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        MovieHierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY 
        ci.movie_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        MovieHierarchy mh ON mk.movie_id = mh.movie_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    ca.total_cast,
    ca.total_actors,
    kc.total_keywords,
    CASE 
        WHEN kc.total_keywords IS NULL THEN 'No Keywords'
        ELSE CONCAT(kc.total_keywords, ' Keywords')
    END AS keyword_info,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY ca.total_cast DESC) AS cast_rank,
    ROW_NUMBER() OVER (ORDER BY mh.production_year DESC, ca.total_cast DESC) AS overall_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastAggregation ca ON mh.movie_id = ca.movie_id
LEFT JOIN 
    KeywordCount kc ON mh.movie_id = kc.movie_id
WHERE 
    mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC, ca.total_cast DESC;
