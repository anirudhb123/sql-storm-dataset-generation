WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        c.name AS director_name,
        m.name AS production_company,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        r.role = 'Director' 
        AND a.production_year >= 2000
    ORDER BY 
        a.production_year DESC
)
SELECT 
    title, 
    production_year, 
    director_name, 
    production_company, 
    STRING_AGG(keyword, ', ') AS keywords
FROM 
    RankedMovies
WHERE 
    rank = 1
GROUP BY 
    title, production_year, director_name, production_company
ORDER BY 
    production_year DESC;
