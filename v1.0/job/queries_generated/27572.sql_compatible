
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(k.id) AS keyword_count,
        COALESCE(SUM(CASE WHEN mci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS movie_company_count
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mci ON t.id = mci.movie_id
    GROUP BY t.id, t.title, t.production_year
),
TopCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
    HAVING COUNT(mc.id) > 1 
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        tc.company_name,
        tc.company_type,
        RANK() OVER (PARTITION BY tc.company_name ORDER BY rm.keyword_count DESC) AS rank
    FROM RankedMovies rm
    JOIN TopCompanies tc ON rm.movie_id = tc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.company_name,
    tm.company_type
FROM TopMovies tm
WHERE tm.rank <= 5 
ORDER BY tm.company_name, tm.keyword_count DESC;
