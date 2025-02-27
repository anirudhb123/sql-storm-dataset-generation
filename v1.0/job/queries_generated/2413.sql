WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
),
MovieWithKeywords AS (
    SELECT 
        t.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        top_movies tm
    JOIN 
        movie_keyword mk ON tm.title = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, '{No Keywords}') AS keywords,
    cd.company_name,
    cd.company_type
FROM 
    TopMovies tm
LEFT JOIN 
    MovieWithKeywords mk ON tm.title = mk.title
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = tm.production_year
WHERE 
    (cd.company_type IS NULL OR cd.company_type = 'Production')
ORDER BY 
    tm.production_year DESC, 
    tm.title;
