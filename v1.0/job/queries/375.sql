WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
    AND 
        r.role IN ('Actor', 'Director')
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
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
    WHERE 
        c.country_code IS NOT NULL
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.actor_role,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(cd.company_name) AS num_companies,
    MAX(rm.actor_rank) AS max_actor_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.production_year = mk.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.production_year = cd.movie_id
WHERE 
    rm.actor_rank <= 3
GROUP BY 
    rm.movie_title, rm.production_year, rm.actor_name, rm.actor_role, mk.keywords
HAVING 
    COUNT(cd.company_name) > 0
ORDER BY 
    rm.production_year DESC, rm.movie_title;
