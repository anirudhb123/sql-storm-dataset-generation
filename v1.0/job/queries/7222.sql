WITH MovieDetails AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        k.keyword, 
        c.name AS company_name, 
        ct.kind AS company_type, 
        ti.info AS movie_info
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN info_type ti ON mi.info_type_id = ti.id
    WHERE t.production_year > 2000 AND k.keyword IS NOT NULL
),
TopMovies AS (
    SELECT 
        title_id, 
        title, 
        production_year,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies,
        STRING_AGG(DISTINCT movie_info, ', ') AS details
    FROM MovieDetails
    GROUP BY title_id, title, production_year
    ORDER BY production_year DESC 
    LIMIT 100
)
SELECT 
    tm.title_id, 
    tm.title, 
    tm.production_year,
    tm.keywords,
    tm.companies,
    tm.details
FROM TopMovies tm
JOIN complete_cast cc ON tm.title_id = cc.movie_id
WHERE cc.status_id = 1
ORDER BY tm.production_year DESC, tm.title;
