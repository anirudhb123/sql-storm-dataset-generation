
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS num_cast_members,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMoviesByCast AS (
    SELECT 
        movie_id,
        title,
        production_year,
        num_cast_members,
        cast_names,
        RANK() OVER (ORDER BY num_cast_members DESC) AS rank
    FROM 
        RankedMovies
),

MoviesWithCompanyInfo AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.num_cast_members,
        tm.cast_names,
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        tm.rank
    FROM 
        TopMoviesByCast AS tm
    LEFT JOIN 
        movie_companies AS mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
)

SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.num_cast_members,
    mw.cast_names,
    mw.company_name,
    mw.company_type
FROM 
    MoviesWithCompanyInfo AS mw
WHERE 
    mw.rank <= 10
ORDER BY 
    mw.num_cast_members DESC;
