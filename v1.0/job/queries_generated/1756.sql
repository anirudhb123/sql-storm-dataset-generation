WITH MovieRatings AS (
    SELECT 
        m.id AS movie_id,
        AVG(pr.rating) AS average_rating
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT 
            movie_id, 
            CAST(info AS FLOAT) AS rating 
         FROM 
            movie_info 
         WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) pr ON m.id = pr.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
), CastCount AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
), GenreKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    a.title AS movie_title,
    COALESCE(mr.average_rating, 0) AS average_rating,
    COALESCE(cc.cast_count, 0) AS cast_members,
    COALESCE(gk.keywords, 'No Keywords') AS genre_keywords
FROM 
    aka_title a
LEFT JOIN 
    MovieRatings mr ON a.id = mr.movie_id
LEFT JOIN 
    CastCount cc ON a.id = cc.movie_id
LEFT JOIN 
    GenreKeywords gk ON a.id = gk.movie_id
WHERE 
    a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    AND (mr.average_rating IS NOT NULL OR cc.cast_count IS NOT NULL)
ORDER BY 
    average_rating DESC NULLS LAST,
    cast_members DESC;
