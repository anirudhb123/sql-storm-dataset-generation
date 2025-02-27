WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),

KeywordMovies AS (
    SELECT 
        t.id AS movie_id,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),

CompanyMovies AS (
    SELECT 
        m.movie_id,
        cc.kind AS company_type,
        cn.name AS company_name
    FROM 
        movie_companies m
    JOIN 
        company_type cc ON m.company_type_id = cc.id
    JOIN 
        company_name cn ON m.company_id = cn.id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_name,
    km.keyword,
    cm.company_name,
    cm.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordMovies km ON rm.movie_id = km.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.actor_name ASC;

