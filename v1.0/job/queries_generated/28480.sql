WITH MovieRatings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(ci.person_id) AS total_cast,
        AVG(rating) AS average_rating
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title
),
KeywordAnalysis AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
TopMovies AS (
    SELECT 
        mr.movie_id,
        mr.title,
        mr.total_cast,
        mr.average_rating,
        ka.keyword,
        ka.keyword_count
    FROM 
        MovieRatings mr
    LEFT JOIN 
        KeywordAnalysis ka ON mr.movie_id = ka.movie_id
    WHERE 
        mr.average_rating IS NOT NULL
    ORDER BY 
        mr.average_rating DESC, mr.total_cast DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.total_cast,
    tm.average_rating,
    STRING_AGG(tm.keyword, ', ') AS keywords
FROM 
    TopMovies tm
GROUP BY 
    tm.movie_id, tm.title, tm.total_cast, tm.average_rating
ORDER BY 
    tm.average_rating DESC;

This SQL query benchmarks string processing by examining the top-rated movies along with their associated keywords, while considering multiple joins and aggregations. The use of `STRING_AGG` enables efficient string manipulation to collect keywords related to each movie title.
