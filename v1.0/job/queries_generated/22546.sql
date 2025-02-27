WITH RankedMovies AS (
    SELECT 
        T.title,
        T.production_year,
        COUNT(CI.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY T.production_year ORDER BY COUNT(CI.id) DESC) AS rank
    FROM 
        aka_title AS T
    LEFT JOIN 
        cast_info AS CI ON T.id = CI.movie_id
    WHERE 
        T.production_year IS NOT NULL
    GROUP BY 
        T.title, T.production_year
),

MoviesWithKeywords AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        STRING_AGG(K.keyword, ', ') AS keywords
    FROM 
        aka_title AS T
    LEFT JOIN 
        movie_keyword AS MK ON T.id = MK.movie_id
    LEFT JOIN 
        keyword AS K ON MK.keyword_id = K.id
    WHERE 
        T.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        T.id, T.title, T.production_year
),

CompanyInfo AS (
    SELECT 
        MC.movie_id, 
        CN.name AS company_name,
        CT.kind AS company_type,
        COUNT(MC.id) AS company_count
    FROM 
        movie_companies AS MC
    JOIN 
        company_name AS CN ON MC.company_id = CN.id
    JOIN 
        company_type AS CT ON MC.company_type_id = CT.id
    GROUP BY 
        MC.movie_id, CN.name, CT.kind
),

MovieDetails AS (
    SELECT 
        R.title,
        R.production_year,
        R.cast_count,
        MK.keywords,
        COALESCE(CI.company_count, 0) AS company_count
    FROM 
        RankedMovies AS R
    LEFT JOIN 
        MoviesWithKeywords AS MK ON R.title = MK.title AND R.production_year = MK.production_year
    LEFT JOIN 
        CompanyInfo AS CI ON CI.movie_id = R.title
)

SELECT 
    title,
    production_year,
    cast_count,
    keywords,
    company_count
FROM 
    MovieDetails
WHERE 
    (cast_count > 10 OR company_count > 2) 
    AND (keywords IS NOT NULL OR production_year IS NOT NULL)
ORDER BY 
    production_year DESC,
    cast_count DESC;

-- Giving special attention to movie titles with NULL or non-standard production years
SELECT DISTINCT 
    title,
    production_year 
FROM 
    aka_title 
WHERE 
    production_year IS NULL OR 
    production_year NOT BETWEEN 1890 AND EXTRACT(YEAR FROM CURRENT_DATE)
    ORDER BY title;
