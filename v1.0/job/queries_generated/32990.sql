WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mk.linked_movie_id,
        mt.title,
        mh.depth + 1
    FROM 
        movie_link mk
    JOIN 
        aka_title mt ON mt.id = mk.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = mk.movie_id
),
high_rating_movies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        MAX(mk.info) AS highest_rating
    FROM 
        movie_companies mc
    JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_info mk ON mc.movie_id = mk.movie_id AND mk.info_type_id = (
            SELECT id FROM info_type WHERE info = 'rating'
        )
    WHERE 
        mc.company_type_id IN (
            SELECT id FROM company_type WHERE kind = 'Production'
        )
    GROUP BY 
        mc.movie_id
    HAVING 
        MAX(mk.info)::numeric > 8.0 -- considering ratings above 8.0
),
final_movies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.depth,
        h.cast_count,
        h.highest_rating
    FROM 
        movie_hierarchy m
    JOIN 
        high_rating_movies h ON m.movie_id = h.movie_id
)
SELECT 
    f.title AS movie_title,
    f.depth,
    f.cast_count,
    f.highest_rating,
    CASE 
        WHEN f.highest_rating IS NULL THEN 'No Rating'
        ELSE 'Rated ' || f.highest_rating
    END AS rating_status
FROM 
    final_movies f
WHERE 
    f.depth = 0 -- top-level movies
ORDER BY 
    f.highest_rating DESC NULLS LAST,
    f.title;

