WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
),
PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
),
MovieDetails AS (
    SELECT 
        pm.title,
        pm.production_year,
        pm.aka_names,
        mk.keyword AS movie_keyword,
        mk.id AS keyword_id,
        ct.kind AS company_type,
        cn.name AS company_name
    FROM 
        PopularMovies pm
    LEFT JOIN 
        movie_keyword mk ON pm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON pm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        pm.rank <= 10
)
SELECT 
    title,
    production_year,
    aka_names,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies
FROM 
    MovieDetails
GROUP BY 
    title, production_year, aka_names
ORDER BY 
    production_year DESC;
