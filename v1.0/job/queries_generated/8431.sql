WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mc.id) AS company_count,
        COUNT(mk.id) AS keyword_count
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.id
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        company_count,
        keyword_count,
        ROW_NUMBER() OVER (ORDER BY company_count DESC, keyword_count DESC) AS rn
    FROM RankedMovies
    WHERE production_year >= 2000
)
SELECT 
    tm.title_id,
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    rt.role,
    ci.nr_order
FROM TopMovies tm
JOIN complete_cast cc ON tm.title_id = cc.movie_id
JOIN cast_info ci ON cc.subject_id = ci.person_id 
JOIN aka_name ak ON ci.person_id = ak.person_id
JOIN role_type rt ON ci.role_id = rt.id
WHERE tm.rn <= 10
ORDER BY tm.production_year DESC, tm.company_count DESC;
