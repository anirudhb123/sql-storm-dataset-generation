WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM RankedMovies
    WHERE rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    ct.kind AS cast_type,
    COUNT(mk.keyword_id) AS keyword_count
FROM TopMovies tm
JOIN movie_companies mc ON tm.movie_id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
JOIN cast_info ci ON tm.movie_id = ci.movie_id
JOIN aka_name ak ON ci.person_id = ak.person_id
JOIN role_type rt ON ci.role_id = rt.id
JOIN comp_cast_type ct ON ci.person_role_id = ct.id
GROUP BY tm.title, tm.production_year, ak.name, ct.kind
ORDER BY tm.production_year DESC, keyword_count DESC;
