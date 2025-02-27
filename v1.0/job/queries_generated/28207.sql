WITH MovieStatistics AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ka.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_title ka ON t.id = ka.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year > 2000
    GROUP BY t.id
),
TopMovies AS (
    SELECT 
        ms.movie_title,
        ms.production_year,
        ms.cast_count,
        ROW_NUMBER() OVER (ORDER BY ms.cast_count DESC) AS rank
    FROM MovieStatistics ms
    WHERE ms.cast_count > 1
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.rank,
    (SELECT STRING_AGG(DISTINCT c.role_id::text, ', ') 
     FROM cast_info c 
     WHERE c.movie_id = t.id) AS roles
FROM TopMovies tm
JOIN title t ON tm.movie_title = t.title
ORDER BY tm.rank
LIMIT 10;
