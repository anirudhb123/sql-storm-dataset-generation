WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
FilteredCompanies AS (
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
    WHERE 
        c.country_code IS NOT NULL AND 
        ct.kind LIKE '%Production%'
)
SELECT 
    a.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    ac.movie_count,
    COALESCE(fc.company_name, 'Independent') AS production_company,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    RankedMovies rm ON ci.movie_id = rm.movie_id
LEFT JOIN 
    ActorMovieCounts ac ON a.person_id = ac.person_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    FilteredCompanies fc ON rm.movie_id = fc.movie_id
WHERE 
    rm.title IS NOT NULL AND 
    a.name IS NOT NULL
GROUP BY 
    a.name, rm.title, rm.production_year, ac.movie_count, fc.company_name
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 0 
ORDER BY 
    rm.production_year DESC, ac.movie_count DESC;
