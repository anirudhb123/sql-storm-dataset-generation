WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyMovies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    cm.company_name,
    cm.company_type,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.title = (SELECT title FROM aka_title WHERE id = cm.movie_id LIMIT 1)
LEFT JOIN 
    MovieKeywords mk ON rm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id LIMIT 1)
WHERE 
    rm.rank <= 5 
    AND rm.actor_count IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
