WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
TopRatedMovies AS (
    SELECT 
        m.movie_id, 
        COALESCE(k.keyword, 'Unknown') AS keyword,
        AVG(mr.rating) AS average_rating
    FROM 
        movie_info m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info_idx mr ON m.movie_id = mr.movie_id AND mr.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        m.movie_id, k.keyword
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    t.keyword,
    COALESCE(rm.average_rating, 0) AS average_rating,
    CASE 
        WHEN rm.average_rating IS NULL THEN 'No Rating'
        WHEN rm.average_rating < 5 THEN 'Poor'
        WHEN rm.average_rating BETWEEN 5 AND 7 THEN 'Average'
        ELSE 'Good'
    END AS rating_quality
FROM 
    RankedMovies r
LEFT JOIN 
    TopRatedMovies rm ON r.movie_id = rm.movie_id
LEFT JOIN 
    aka_name an ON r.movie_id = an.person_id
WHERE 
    r.rank <= 10
    AND (r.production_year > 2000 OR r.production_year IS NULL)
ORDER BY 
    r.production_year DESC, 
    r.title ASC
LIMIT 50;
