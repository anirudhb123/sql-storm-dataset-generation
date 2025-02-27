WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        1 AS depth
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
        AND t.production_year >= 2000
        
    UNION ALL
    
    SELECT 
        mh.movie_id,
        t.title,
        mh.depth + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS t ON ml.linked_movie_id = t.id
),
AggregatedData AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(DISTINCT c.id) AS cast_count,
        AVG(p.rating) AS average_rating
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        cast_info AS c ON mh.movie_id = c.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            AVG(rating) AS rating 
         FROM 
            movie_info 
         WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
         GROUP BY movie_id) AS p ON mh.movie_id = p.movie_id
    GROUP BY 
        mh.movie_id, mh.title
),
RankedMovies AS (
    SELECT 
        ad.movie_id,
        ad.title,
        ad.cast_count,
        ad.average_rating,
        RANK() OVER (ORDER BY ad.average_rating DESC, ad.cast_count DESC) AS rank
    FROM 
        AggregatedData AS ad
    WHERE 
        ad.average_rating IS NOT NULL
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.cast_count,
    rm.average_rating,
    CASE 
        WHEN rm.average_rating >= 8 THEN 'High Rating'
        WHEN rm.average_rating >= 5 THEN 'Medium Rating'
        ELSE 'Low Rating'
    END AS rating_category
FROM 
    RankedMovies AS rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.average_rating DESC, rm.cast_count DESC;
