WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
),
MovieStats AS (
    SELECT 
        rm.movie_id,
        rm.title,
        COUNT(ci.person_id) AS cast_count,
        MAX(CASE WHEN km.keyword IS NOT NULL THEN 1 ELSE 0 END) AS has_keyword,
        AVG(COALESCE(mr.rating, 0)) AS avg_rating
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        (SELECT movie_id, AVG(rating) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') GROUP BY movie_id) mr 
    ON 
        rm.movie_id = mr.movie_id
    GROUP BY 
        rm.movie_id, rm.title
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.cast_count,
    CASE WHEN ms.has_keyword = 1 THEN 'Yes' ELSE 'No' END AS has_keyword,
    ms.avg_rating,
    CASE 
        WHEN ms.avg_rating >= 8 THEN 'Highly Rated'
        WHEN ms.avg_rating >= 5 THEN 'Moderately Rated'
        ELSE 'Poorly Rated'
    END AS rating_category
FROM 
    MovieStats ms
WHERE 
    ms.cast_count > 0
ORDER BY 
    ms.avg_rating DESC, ms.title;


