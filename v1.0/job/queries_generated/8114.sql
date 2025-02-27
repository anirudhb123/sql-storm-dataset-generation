WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT m.name) AS production_companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_in_year
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    JOIN aka_title ak ON ak.movie_id = t.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name m ON m.id = mc.company_id
    GROUP BY t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        aka_names,
        production_companies
    FROM RankedMovies
    WHERE rank_in_year <= 10
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    STRING_AGG(DISTINCT pn.info, '; ') AS person_info
FROM TopMovies tm
LEFT JOIN cast_info ci ON ci.movie_id = tm.movie_id
LEFT JOIN person_info pn ON pn.person_id = ci.person_id
LEFT JOIN unnest(tm.aka_names) AS ak(name) ON true
GROUP BY tm.movie_id, tm.title, tm.production_year, tm.total_cast
ORDER BY tm.production_year DESC, tm.total_cast DESC;
