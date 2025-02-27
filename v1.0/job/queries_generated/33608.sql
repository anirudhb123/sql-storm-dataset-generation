WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        CONCAT(m.title, ' (Linked)') AS title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- Limit the hierarchy depth
),
AggregatedData AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS ci ON m.id = ci.movie_id
    LEFT JOIN 
        movie_info AS mi ON m.id = mi.movie_id AND mi.info_type_id IN (1, 2)
    GROUP BY 
        m.id, m.title
),
RankedMovies AS (
    SELECT 
        ad.movie_id,
        ad.title,
        ad.total_cast,
        ad.cast_with_notes,
        RANK() OVER (ORDER BY ad.total_cast DESC) AS cast_rank
    FROM 
        AggregatedData ad
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    rm.total_cast,
    rm.cast_with_notes,
    rm.cast_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedMovies rm ON mh.movie_id = rm.movie_id
WHERE 
    rm.total_cast > 5 OR mh.level = 1
ORDER BY 
    mh.production_year DESC, rm.cast_rank ASC;
