WITH RECURSIVE RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id DESC) AS rank_per_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year 
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 5
),
PersonRoles AS (
    SELECT 
        c.person_id,
        p.name AS person_name,
        COUNT(c.role_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.person_id, p.name
),
MovieCompanyDetails AS (
    SELECT 
        m.id AS movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieKeywordDetails AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COUNT(DISTINCT pr.person_id) AS unique_actors,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords_used,
    STRING_AGG(DISTINCT mc.company_name || ' (' || mc.company_type || ')', '; ') AS companies_involved
FROM 
    TopMovies tm
LEFT OUTER JOIN 
    PersonRoles pr ON pr.role_count > 0 
LEFT JOIN 
    MovieKeywordDetails mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanyDetails mc ON tm.movie_id = mc.movie_id
WHERE 
    tm.production_year BETWEEN 2000 AND 2023
    AND (pr.person_id IS NOT NULL OR mc.company_name IS NULL)
GROUP BY 
    tm.movie_title,
    tm.production_year
HAVING 
    COUNT(DISTINCT pr.person_id) > 2
    OR COUNT(DISTINCT mc.company_name) > 1
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title ASC;