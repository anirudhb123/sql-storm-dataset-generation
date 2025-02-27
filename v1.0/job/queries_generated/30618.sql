WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Starting with movies from the year 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(r.rating) AS average_rating
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info c ON c.movie_id = m.id
    LEFT JOIN 
        (SELECT movie_id, AVG(rating) AS rating FROM movie_info GROUP BY movie_id) r ON r.movie_id = m.id
    GROUP BY 
        m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mi.keywords,
    mi.actor_count,
    mi.average_rating,
    CASE 
        WHEN mi.average_rating IS NULL THEN 'No ratings available'
        WHEN mi.average_rating >= 8.0 THEN 'Highly Rated'
        WHEN mi.average_rating >= 5.0 THEN 'Moderately Rated'
        ELSE 'Poorly Rated'
    END AS rating_category,
    COALESCE((SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = mh.movie_id), 0) AS complete_cast_count
FROM 
    MovieHierarchy mh
JOIN 
    MovieInfo mi ON mi.movie_id = mh.movie_id
WHERE 
    mh.depth < 3  -- Limit the depth for performance
ORDER BY 
    mh.production_year DESC, 
    mi.average_rating DESC
LIMIT 100;  -- Limit the output for benchmarking
