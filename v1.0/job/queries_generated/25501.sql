WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS known_as,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY a.id
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        known_as,
        keywords,
        cast_count
    FROM RankedMovies
    WHERE year_rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.known_as,
    tm.keywords,
    tm.cast_count,
    AVG(ti.info) AS avg_rating
FROM TopMovies tm
LEFT JOIN movie_info mi ON tm.movie_title = mi.info
LEFT JOIN info_type ti ON mi.info_type_id = ti.id
GROUP BY 
    tm.movie_title,
    tm.production_year,
    tm.known_as,
    tm.keywords,
    tm.cast_count
ORDER BY 
    tm.production_year DESC,
    tm.cast_count DESC;
