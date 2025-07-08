
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank,
        COUNT(c.id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 3
),
MovieWithCompanies AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.title_id, tm.title, tm.production_year
),
MovieKeywords AS (
    SELECT 
        mt.title_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        TopMovies mt
    LEFT JOIN 
        movie_keyword mk ON mt.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.title_id
)

SELECT 
    mw.title,
    mw.production_year,
    mw.companies,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    MovieWithCompanies mw
LEFT JOIN 
    MovieKeywords mk ON mw.title_id = mk.title_id
WHERE 
    mw.production_year = (
        SELECT MAX(production_year) 
        FROM MovieWithCompanies
    )
ORDER BY 
    mw.title ASC;
