
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
),
MovieCompanies AS (
    SELECT 
        m.title,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_companies mc ON m.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(mc.company_name, 'Independent') AS company_name,
    COALESCE(mc.company_type, 'N/A') AS company_type,
    LISTAGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies m
LEFT JOIN 
    movie_keyword mk ON m.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieCompanies mc ON mc.title = m.title
GROUP BY 
    m.title, m.production_year, mc.company_name, mc.company_type
ORDER BY 
    m.production_year DESC, m.title;
