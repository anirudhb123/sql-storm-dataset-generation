WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.keyword_count
    FROM RankedMovies rm
    WHERE rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    cn.name AS company_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM TopMovies tm
JOIN cast_info ci ON tm.movie_id = ci.movie_id
JOIN aka_name ak ON ci.person_id = ak.person_id
JOIN movie_companies mc ON tm.movie_id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
GROUP BY tm.movie_id, ak.name, cn.name
ORDER BY tm.production_year DESC, tm.title ASC;
