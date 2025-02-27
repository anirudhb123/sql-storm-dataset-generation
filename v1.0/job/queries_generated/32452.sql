WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON at.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy AS mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 5
),

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No Info') AS info,
        COUNT(ci.id) AS cast_count,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE NULL END) AS avg_order,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_info AS mi ON m.id = mi.movie_id
    LEFT JOIN 
        cast_info AS ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = ci.person_id
    GROUP BY 
        m.id, m.title, mi.info
)

SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    COALESCE(m.info, 'No Info') AS info,
    m.cast_count,
    m.role_count,
    m.avg_order,
    m.actor_names,
    ROW_NUMBER() OVER (PARTITION BY h.level ORDER BY h.production_year DESC) AS rank
FROM 
    MovieHierarchy AS h
LEFT JOIN 
    MovieInfo AS m ON h.movie_id = m.movie_id
ORDER BY 
    h.level, h.production_year DESC;
