WITH RECURSIVE movie_hierarchy AS (
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
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
average_ratings AS (
    SELECT 
        ci.movie_id,
        AVG(pi.info::numeric) AS avg_rating
    FROM 
        complete_cast ci
    JOIN 
        person_info pi ON ci.subject_id = pi.person_id 
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        ci.movie_id
),
cast_distribution AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ar.avg_rating, 0) AS average_rating,
    COALESCE(cd.cast_count, 0) AS cast_count,
    CASE 
        WHEN ar.avg_rating IS NULL THEN 'No ratings yet'
        WHEN ar.avg_rating > 7 THEN 'Highly Rated'
        WHEN ar.avg_rating > 5 THEN 'Moderately Rated'
        ELSE 'Poorly Rated'
    END AS rating_description,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    average_ratings ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    cast_distribution cd ON mh.movie_id = cd.movie_id
WHERE 
    mh.level <= 2
ORDER BY 
    mh.production_year DESC,
    average_rating DESC NULLS LAST;
