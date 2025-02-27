WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(cc.movie_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.movie_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
Keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(kw.keyword_list, 'No keywords') AS keywords,
    (SELECT AVG(p.info::numeric) 
     FROM person_info p 
     WHERE p.person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id = tm.movie_id) 
     AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS avg_rating
FROM 
    TopMovies tm
LEFT JOIN 
    Keywords kw ON tm.movie_id = kw.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
