
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS movie_rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 5
),
CompanyDetails AS (
    SELECT 
        cm.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies cm
    JOIN 
        company_name cn ON cm.company_id = cn.id
    JOIN 
        company_type ct ON cm.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    cd.company_name,
    cd.company_type,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    tm.title, tm.production_year, cd.company_name, cd.company_type
ORDER BY 
    tm.production_year DESC, total_actors DESC;
