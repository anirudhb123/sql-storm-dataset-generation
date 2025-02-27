WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM aka_title a
    JOIN movie_companies mc ON mc.movie_id = a.id
    JOIN company_name cn ON cn.id = mc.company_id
    LEFT JOIN cast_info c ON c.movie_id = a.id
    WHERE a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count 
    FROM RankedMovies 
    WHERE rn <= 5
),
MovieKeywords AS (
    SELECT 
        mt.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON k.id = mt.keyword_id
    GROUP BY mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN tm.cast_count > 10 THEN 'Large Cast'
        WHEN tm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM TopMovies tm
LEFT JOIN MovieKeywords mk ON mk.movie_id = (
    SELECT m.id 
    FROM aka_title m 
    WHERE m.title = tm.title AND m.production_year = tm.production_year
)
ORDER BY tm.production_year DESC, tm.cast_count DESC;
