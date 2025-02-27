WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM title AS m
    JOIN movie_info AS mi ON m.id = mi.movie_id
    JOIN movie_keyword AS mk ON m.id = mk.movie_id
    JOIN keyword AS k ON mk.keyword_id = k.id
    JOIN complete_cast AS cc ON m.id = cc.movie_id
    JOIN cast_info AS c ON cc.subject_id = c.id
    JOIN aka_name AS a ON c.person_id = a.person_id
    WHERE m.production_year BETWEEN 2000 AND 2023
    GROUP BY m.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        total_cast, 
        cast_names, 
        keywords,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    tm.keywords
FROM TopMovies AS tm
WHERE tm.rank <= 10
ORDER BY tm.rank;
