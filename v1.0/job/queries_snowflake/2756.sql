
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_count <= 5
),
MovieGenres AS (
    SELECT 
        m.title,
        LISTAGG(DISTINCT g.keyword, ', ') WITHIN GROUP (ORDER BY g.keyword) AS genres
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword g ON mk.keyword_id = g.id
    GROUP BY 
        m.title
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    mg.genres,
    ci.company_count,
    ci.company_types
FROM 
    TopMovies tm
LEFT JOIN 
    MovieGenres mg ON tm.title = mg.title
LEFT JOIN 
    CompanyInfo ci ON tm.movie_id = ci.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
