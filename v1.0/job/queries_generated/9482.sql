WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        cn.name AS company_name,
        COUNT(DISTINCT mc.person_id) AS num_actors
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    GROUP BY t.title, t.production_year, cn.name
),
TopRankedMovies AS (
    SELECT 
        title,
        production_year,
        company_name,
        num_actors,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY num_actors DESC) AS rn
    FROM RankedMovies
)
SELECT 
    title,
    production_year,
    company_name,
    num_actors
FROM TopRankedMovies
WHERE rn <= 5
ORDER BY production_year, num_actors DESC;
