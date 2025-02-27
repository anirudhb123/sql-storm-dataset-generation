WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year AS year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        t.kind AS movie_kind,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS movie_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        kind_type t ON a.kind_id = t.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, t.kind
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT c.country_code, ', ') AS countries
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
CompleteMovieData AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.year,
        rm.keywords,
        rm.movie_kind,
        mcc.company_name,
        mcc.company_type,
        mcc.countries
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCompanies mcc ON rm.movie_id = mcc.movie_id
)
SELECT 
    movie_id,
    movie_title,
    year,
    keywords,
    movie_kind,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies,
    countries
FROM 
    CompleteMovieData
WHERE 
    movie_rank = 1
GROUP BY 
    movie_id, movie_title, year, keywords, movie_kind, countries
ORDER BY 
    year DESC, movie_title;
