
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
), 
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        a.title,
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        TopMovies a
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = a.title AND production_year = a.production_year LIMIT 1)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
), 
MovieCompanies AS (
    SELECT 
        a.title,
        COALESCE(c.name, 'No Company') AS company_name,
        COALESCE(ct.kind, 'No Type') AS company_type
    FROM 
        TopMovies a
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = a.title AND production_year = a.production_year LIMIT 1)
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(mk.keyword, 'No Keyword') AS keyword,
    COALESCE(c.company_name, 'No Company') AS company_name,
    COALESCE(c.company_type, 'No Type') AS company_type
FROM 
    TopMovies m
LEFT JOIN 
    MovieKeywords mk ON m.title = mk.title
LEFT JOIN 
    MovieCompanies c ON m.title = c.title
WHERE 
    m.actor_count > 0
ORDER BY 
    m.production_year DESC, m.actor_count DESC;
