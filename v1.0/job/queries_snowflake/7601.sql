
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') AS actors
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE t.production_year > 2000
      AND cn.country_code = 'USA'
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actors,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    it.info AS additional_info
FROM TopMovies tm
LEFT JOIN movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN info_type it ON mi.info_type_id = it.id
WHERE tm.rank <= 10
ORDER BY tm.rank;
