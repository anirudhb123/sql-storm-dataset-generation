
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        title.kind_id,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rnk
    FROM 
        title
    WHERE 
        title.production_year BETWEEN 2000 AND 2023
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year
    FROM 
        RankedMovies 
    WHERE 
        rnk <= 5
),
CastDetails AS (
    SELECT 
        cast_info.movie_id,
        COUNT(cast_info.person_id) AS total_cast,
        LISTAGG(DISTINCT aka_name.name, ', ') WITHIN GROUP (ORDER BY aka_name.name) AS cast_names
    FROM 
        cast_info
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        cast_info.movie_id
),
CompanyMovies AS (
    SELECT 
        movie_companies.movie_id,
        COUNT(DISTINCT company_name.id) AS total_companies,
        LISTAGG(DISTINCT company_name.name, ', ') WITHIN GROUP (ORDER BY company_name.name) AS company_names
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    WHERE 
        company_name.country_code = 'USA'
    GROUP BY 
        movie_companies.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    cd.total_cast,
    cd.cast_names,
    cm.total_companies,
    cm.company_names
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyMovies cm ON tm.movie_id = cm.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
