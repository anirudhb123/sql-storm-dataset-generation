WITH RECURSIVE ActorHierarchy AS (
    -- Base case: Select actors and their associated movies
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        ct.kind AS role_type,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    INNER JOIN 
        title m ON ci.movie_id = m.id
    INNER JOIN 
        role_type ct ON ci.role_id = ct.id
),

CompanyInfo AS (
    -- Get companies associated with movies
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        c.country_code,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
),

FilteredMovies AS (
    -- Select movies along with their company names, filtering by production year
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT ci.company_name) AS companies,
        m.production_year
    FROM 
        title m
    LEFT JOIN 
        CompanyInfo ci ON m.id = ci.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id
),

DirectorInfo AS (
    -- Get directors of filtered movies
    SELECT 
        m.title,
        ak.name AS director_name,
        COUNT(DISTINCT ci.actor_id) AS actor_count
    FROM 
        FilteredMovies fm
    INNER JOIN 
        complete_cast cc ON fm.movie_id = cc.movie_id
    INNER JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    WHERE 
        cc.status_id = 1 -- Assuming 1 is for the directing role
    GROUP BY 
        m.title, ak.name
)

-- Final selection with window function and complex filters
SELECT 
    ah.actor_name,
    ah.movie_title,
    ah.production_year,
    di.director_name,
    di.actor_count,
    COALESCE(fm.companies, '{}') AS movie_companies
FROM 
    ActorHierarchy ah
LEFT JOIN 
    DirectorInfo di ON ah.movie_title = di.title
LEFT JOIN 
    FilteredMovies fm ON ah.movie_title = fm.title
WHERE 
    ah.rn = 1 -- Get only the latest movie per actor
ORDER BY 
    ah.actor_name, ah.production_year DESC;
