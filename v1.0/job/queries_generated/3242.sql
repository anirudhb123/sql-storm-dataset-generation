WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(cd.company_name, 'Independent') AS production_company,
    (SELECT STRING_AGG(DISTINCT a.name, ', ') FROM cast_info ci
     JOIN aka_name a ON ci.person_id = a.person_id 
     WHERE ci.movie_id = tm.movie_id) AS cast_members
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_title = (SELECT title FROM aka_title WHERE id = cd.movie_id)
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title;
