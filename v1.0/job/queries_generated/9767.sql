WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id, 
        tm.title, 
        tm.production_year, 
        m.name AS company_name, 
        c.kind AS company_type
    FROM 
        TopMovies tm
    JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        company_type c ON mc.company_type_id = c.id
)
SELECT 
    md.title, 
    md.production_year, 
    STRING_AGG(md.company_name, ', ') AS companies, 
    STRING_AGG(md.company_type, ', ') AS company_types
FROM 
    MovieDetails md
GROUP BY 
    md.title, 
    md.production_year
ORDER BY 
    md.production_year DESC, 
    md.title;
