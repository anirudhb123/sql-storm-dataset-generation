WITH RECURSIVE CompanyHierarchy AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        1 AS level
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ch.level + 1
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    JOIN 
        CompanyHierarchy ch ON m.movie_id = ch.movie_id
    WHERE 
        ch.level < 3
), 
RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
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
    COALESCE(ch.company_name, 'Unknown Company') AS company_name,
    COALESCE(ch.company_type, 'Unknown Type') AS company_type,
    rm.actor_count,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyHierarchy ch ON rm.title = ch.movie_id  -- Assuming title matches movie_id here for the sake of illustration
LEFT JOIN 
    MovieKeywords mk ON rm.title = mk.movie_id
WHERE 
    rm.production_year >= 2000 
    AND (rm.actor_count > 5 OR mk.keywords IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC
LIMIT 10;
