WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Starting point for movies from the year 2000 onwards

    UNION ALL

    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title mt ON mh.kind_id = mt.kind_id
    WHERE 
        mh.production_year < mt.production_year  -- evolving selection based on production year
),

AggregatedRatings AS (
    SELECT 
        mi.movie_id,
        AVG(rating) AS avg_rating
    FROM 
        movie_info mi
    JOIN 
        (SELECT movie_id, rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating'))
    WHERE 
        rating IS NOT NULL
    GROUP BY 
        mi.movie_id
),

RankedMovies AS (
    SELECT 
        mh.movie_title,
        mh.production_year,
        ar.avg_rating,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY ar.avg_rating DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        AggregatedRatings ar ON mh.title = ar.movie_id
)

SELECT 
    r.movie_title,
    r.production_year,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    c.name AS cast_member,
    COALESCE(ct.kind, 'Unknown') AS cast_type
FROM 
    RankedMovies r
LEFT JOIN 
    cast_info ci ON r.movie_id = ci.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
LEFT JOIN 
    comp_cast_type ct ON ci.role_id = ct.id
WHERE 
    r.rank <= 10 AND
    (r.avg_rating IS NOT NULL OR r.production_year >= 2010)  -- Filtering based on conditions
ORDER BY 
    r.production_year, 
    r.avg_rating DESC;
