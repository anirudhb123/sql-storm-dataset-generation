
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_role_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_role_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, ct.kind
)
SELECT 
    tm.title,
    tm.production_year,
    cd.companies,
    cd.company_type
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = (SELECT t.title FROM aka_title t WHERE t.id = cc.movie_id)
LEFT JOIN 
    CompanyDetails cd ON cc.movie_id = cd.movie_id
WHERE 
    cd.companies IS NOT NULL
    AND tm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    tm.production_year DESC, tm.title;
