WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY COUNT(c.id) DESC) as rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(co.name) AS companies_involved,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
)
SELECT 
    tm.title,
    tm.production_year,
    cd.companies_involved,
    cd.company_type,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = tm.movie_id) AS total_cast,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = tm.movie_id) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
WHERE 
    tm.production_year > 2000
ORDER BY 
    tm.production_year DESC, tm.title;
