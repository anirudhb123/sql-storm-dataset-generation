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
        ml.linked_movie_id,
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
        at.production_year >= 2000
),
MovieRatings AS (
    SELECT 
        m.id AS movie_id,
        AVG(CASE WHEN r.rating IS NULL THEN 0 ELSE r.rating END) AS average_rating,
        COUNT(r.rating) AS total_votes
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT 
            movie_id,
            CAST(info AS FLOAT) AS rating
         FROM 
            movie_info 
         WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) r ON m.id = r.movie_id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mr.average_rating,
        mr.total_votes,
        RANK() OVER (PARTITION BY mh.level ORDER BY mr.average_rating DESC) AS rank
    FROM 
        MovieHierarchy mh
    JOIN 
        MovieRatings mr ON mh.movie_id = mr.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.average_rating,
    tm.total_votes,
    CASE 
        WHEN tm.rank <= 5 THEN 'Top 5'
        WHEN tm.rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS rank_category
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.average_rating DESC;
