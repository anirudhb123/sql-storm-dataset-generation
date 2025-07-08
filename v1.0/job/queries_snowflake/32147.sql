
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m 
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
    WHERE 
        mh.level < 3
),
AggregatedData AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.id) AS cast_count,
        LISTAGG(DISTINCT p.name, ', ') AS cast_names,
        AVG(CAST(mi.info AS numeric)) AS average_rating
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name p ON c.person_id = p.person_id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
FilteredData AS (
    SELECT 
        a.movie_id,
        t.title,
        t.production_year,
        a.cast_count,
        a.cast_names,
        a.average_rating
    FROM
        AggregatedData a
    JOIN 
        aka_title t ON a.movie_id = t.id
    WHERE 
        a.cast_count > 0 AND 
        (a.average_rating IS NULL OR a.average_rating > 6.0)
)
SELECT 
    fd.movie_id,
    fd.title,
    fd.production_year,
    fd.cast_count,
    fd.cast_names,
    fd.average_rating
FROM 
    FilteredData fd
ORDER BY 
    fd.average_rating DESC, 
    fd.production_year DESC
LIMIT 10;
