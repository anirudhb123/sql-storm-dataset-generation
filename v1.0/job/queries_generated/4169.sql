WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rn
    FROM aka_title at
    LEFT JOIN movie_companies mc ON at.id = mc.movie_id
    GROUP BY at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        company_count
    FROM RankedMovies
    WHERE rn <= 5
),
CastInfoWithNames AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_type,
        ci.nr_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    STRING_AGG(cast.actor_name || ' (' || cast.role_type || ')', ', ') AS cast_list
FROM TopMovies tm
LEFT JOIN CastInfoWithNames cast ON tm.title LIKE '%' || cast.movie_id || '%'
GROUP BY tm.title, tm.production_year, tm.company_count
ORDER BY tm.production_year DESC, tm.company_count DESC
LIMIT 10;
