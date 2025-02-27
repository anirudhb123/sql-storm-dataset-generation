WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        keyword 
    FROM 
        RankedMovies 
    WHERE 
        rank_year <= 5
),
CastDetails AS (
    SELECT 
        ci.movie_id, 
        GROUP_CONCAT(a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        GROUP_CONCAT(cn.name, ', ') AS company_names,
        GROUP_CONCAT(ct.kind, ', ') AS company_types
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
    tm.keyword, 
    cd.cast_names, 
    co.company_names, 
    co.company_types
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyDetails co ON tm.movie_id = co.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
