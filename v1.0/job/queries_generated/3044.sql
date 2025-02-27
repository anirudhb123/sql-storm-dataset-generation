WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 1
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_in_year <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        mci.kind AS company_kind,
        c.name AS company_name
    FROM 
        TopMovies tm
    JOIN 
        complete_cast cc ON cc.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = cc.movie_id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        company_type mci ON mci.id = mc.company_type_id 
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    COALESCE(md.company_kind, 'N/A') AS company_kind,
    COUNT(DISTINCT mc.id) OVER (PARTITION BY md.title) AS total_movie_companies
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT id FROM aka_title WHERE title = md.title)
WHERE 
    mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')
ORDER BY 
    md.production_year DESC, 
    md.title;
