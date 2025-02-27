WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        COALESCE(SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_cast
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.id = ci.movie_id
    LEFT JOIN movie_companies mc ON mc.movie_id = at.id
    GROUP BY at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast
    FROM RankedMovies
    WHERE rank <= 5
),
PersonInfo AS (
    SELECT 
        ak.name,
        p.info AS person_info
    FROM aka_name ak
    JOIN person_info p ON ak.person_id = p.person_id
    WHERE p.info_type_id IN (SELECT id FROM info_type WHERE info IN ('bio', 'awards'))
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    STRING_AGG(DISTINCT pi.name, ', ') AS cast_names,
    COUNT(DISTINCT pi.person_info) AS unique_info_count
FROM TopMovies tm
LEFT JOIN cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN PersonInfo pi ON ci.person_id = (SELECT ak.person_id FROM aka_name ak WHERE ak.id = ci.person_id)
GROUP BY tm.movie_id, tm.title, tm.production_year, tm.total_cast
ORDER BY tm.production_year DESC, tm.total_cast DESC;
