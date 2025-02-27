
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank_year
    FROM aka_title a
    JOIN movie_keyword mk ON mk.movie_id = a.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE a.production_year >= 2000
),
MovieWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM RankedMovies rm
    LEFT JOIN cast_info ci ON ci.movie_id = rm.movie_id
    GROUP BY rm.movie_id, rm.title, rm.production_year
),
MoviesAboveThreshold AS (
    SELECT 
        mwc.movie_id,
        mwc.title,
        mwc.production_year,
        mwc.cast_count
    FROM MovieWithCast mwc
    WHERE mwc.cast_count > 5
),
TopMovies AS (
    SELECT 
        mab.movie_id,
        mab.title,
        mab.production_year,
        mab.cast_count,
        ROW_NUMBER() OVER (ORDER BY mab.cast_count DESC) AS top_rank
    FROM MoviesAboveThreshold mab
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM TopMovies tm
LEFT JOIN aka_name ak ON ak.person_id IN (
    SELECT ci.person_id 
    FROM cast_info ci 
    WHERE ci.movie_id = tm.movie_id
)
WHERE tm.top_rank <= 10
GROUP BY tm.movie_id, tm.title, tm.production_year, tm.cast_count
ORDER BY tm.cast_count DESC;
