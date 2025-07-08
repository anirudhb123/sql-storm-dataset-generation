
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name), 'No Actors') AS actors,
        COALESCE LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword), 'No Keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ak.id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actors, 
        keywords 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieCompanies AS (
    SELECT 
        m.movie_id, 
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies 
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title AS movie_title,
    tm.production_year,
    tm.actors,
    tm.keywords,
    mc.companies
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCompanies mc ON tm.movie_id = mc.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
