
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count
    FROM RankedMovies rm
    WHERE rm.rank <= 5
), 
GenreKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title m ON mk.movie_id = m.id
    GROUP BY m.movie_id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    COALESCE(gk.keywords, 'No Keywords') AS keywords
FROM TopMovies tm
LEFT JOIN GenreKeywords gk ON tm.movie_title = (SELECT title FROM aka_title WHERE id = gk.movie_id)
ORDER BY tm.production_year DESC, tm.cast_count DESC;
