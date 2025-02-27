WITH RECURSIVE MovieHierarchy AS (
    -- Recursive CTE to find all movies that share a cast member with a specific movie
    SELECT DISTINCT 
        c.movie_id AS related_movie_id,
        c.person_id AS cast_member_id
    FROM 
        cast_info c
    JOIN 
        aka_title a ON c.movie_id = a.movie_id
    WHERE 
        a.title ILIKE '%Inception%'
    
    UNION ALL
    
    SELECT DISTINCT 
        c.movie_id,
        c.person_id
    FROM 
        cast_info c
    JOIN 
        MovieHierarchy mh ON c.person_id = mh.cast_member_id
    WHERE 
        c.movie_id <> mh.related_movie_id
),
-- CTE to get movies with specific keywords
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
-- CTE to calculate the number of appearances of each movie and their average ratings
MovieRatings AS (
    SELECT 
        m.id AS movie_id,
        COUNT(c.id) AS cast_count,
        AVG(COALESCE(r.rating, 0)) AS average_rating
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        (SELECT movie_id, AVG(rating) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') GROUP BY movie_id) r ON m.id = r.movie_id
    GROUP BY 
        m.id
)
-- Final selection combining all data
SELECT 
    m.id AS movie_id,
    m.title,
    mk.keywords,
    mr.cast_count,
    mr.average_rating,
    CASE 
        WHEN mr.average_rating IS NULL THEN 'No Rating'
        WHEN mr.average_rating >= 7 THEN 'Highly Rated'
        WHEN mr.average_rating BETWEEN 5 AND 7 THEN 'Moderately Rated'
        ELSE 'Low Rating'
    END AS rating_category,
    COALESCE(ah.name, 'Unknown') AS actor_name
FROM 
    aka_title m
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.related_movie_id
LEFT JOIN 
    MovieKeywords mk ON m.id = mk.movie_id
LEFT JOIN 
    MovieRatings mr ON m.id = mr.movie_id
LEFT JOIN 
    aka_name ah ON mh.cast_member_id = ah.person_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND (m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv_series')))
ORDER BY 
    mr.average_rating DESC,
    m.title ASC
LIMIT 100;
