
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year
    FROM RankedMovies rm
    WHERE rm.rank <= 5
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM movie_companies m
    JOIN company_name co ON m.company_id = co.id
    GROUP BY m.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    ci.companies,
    mk.keywords
FROM TopMovies tm
LEFT JOIN CompanyInfo ci ON tm.production_year = ci.movie_id
LEFT JOIN MovieKeywords mk ON tm.production_year = mk.movie_id
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC;
