
WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalOutput AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        tm.cast_count,
        COALESCE(mc.company_names, 'Unknown') AS production_companies,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieCompanies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year LIMIT 1)
)

SELECT 
    movie_title, 
    production_year, 
    cast_count,
    production_companies,
    keywords
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, 
    cast_count DESC;
