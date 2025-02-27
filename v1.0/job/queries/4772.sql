WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
),
MovieActors AS (
    SELECT 
        DISTINCT a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        title t ON t.id = c.movie_id
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON cn.id = m.company_id
    GROUP BY 
        m.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    COALESCE(ma.actor_name, 'No Actor') AS featured_actor,
    COALESCE(ci.companies, 'No Companies') AS production_companies,
    COALESCE(mk.keywords, 'No Keywords') AS associated_keywords
FROM 
    RankedMovies r
LEFT JOIN 
    MovieActors ma ON r.title_id = ma.movie_id AND r.rank <= 3
LEFT JOIN 
    CompanyInfo ci ON r.title_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON r.title_id = mk.movie_id
WHERE 
    r.production_year >= 2000
ORDER BY 
    r.production_year DESC, r.title ASC;
