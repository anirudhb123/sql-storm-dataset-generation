WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    GROUP BY t.id, t.title, t.production_year
), 
MovieGenres AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
), 
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        mg.genres
    FROM RankedMovies rm
    LEFT JOIN MovieGenres mg ON rm.movie_id = mg.movie_id
    WHERE rn <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.genres, 'No genres available') AS genres,
    COALESCE(AVG(pi.info::FLOAT), 0) AS avg_person_age
FROM TopMovies tm
LEFT JOIN person_info pi ON pi.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = tm.movie_id) 
GROUP BY tm.title, tm.production_year, tm.genres
ORDER BY tm.production_year DESC, avg_person_age DESC;
