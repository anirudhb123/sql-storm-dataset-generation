WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM aka_title a
    JOIN movie_info mi ON a.movie_id = mi.movie_id
    JOIN title t ON a.movie_id = t.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY a.title, t.production_year
),
TopMovies AS (
    SELECT movie_title, production_year
    FROM RankedMovies
    WHERE rank <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(distinct mc.company_id) AS total_companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, cn.name, ct.kind
)
SELECT 
    tm.movie_title,
    tm.production_year,
    cd.company_name,
    cd.company_type,
    COALESCE(cd.total_companies, 0) AS total_companies,
    CASE 
        WHEN cd.total_companies IS NULL THEN 'No Companies'
        ELSE 'Companies Present'
    END AS company_status
FROM TopMovies tm
LEFT JOIN CompanyDetails cd ON tm.movie_title = cd.movie_id
ORDER BY tm.production_year DESC, tm.movie_title;
