
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS known_actors,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS associated_keywords
    FROM aka_title mt
    JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.known_actors,
        rm.associated_keywords,
        RANK() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM RankedMovies rm
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.known_actors,
    tm.associated_keywords
FROM TopMovies tm
WHERE tm.rank <= 10
ORDER BY tm.production_year DESC, tm.cast_count DESC;
