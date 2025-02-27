WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        row_number() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rn
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
ActorsWithRoles AS (
    SELECT
        aka_name.person_id,
        aka_name.name AS actor_name,
        cast_info.movie_id,
        role_type.role,
        ROW_NUMBER() OVER (PARTITION BY cast_info.movie_id ORDER BY cast_info.nr_order) AS role_rank
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    JOIN 
        role_type ON cast_info.role_id = role_type.id
    WHERE 
        aka_name.name IS NOT NULL
),
PopularMovies AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT person_id) AS actor_count
    FROM 
        cast_info
    GROUP BY 
        movie_id
    HAVING 
        COUNT(DISTINCT person_id) > 5
),
CompanyInfo AS (
    SELECT 
        movie_companies.movie_id,
        company_name.name AS company_name,
        company_type.kind AS company_type
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        company_type ON movie_companies.company_type_id = company_type.id
)
SELECT 
    RM.movie_title,
    RM.production_year,
    AW.role_rank,
    AW.actor_name,
    COALESCE(CI.company_name, 'Independent') AS production_company,
    CASE 
        WHEN AW.role IS NULL THEN 'Unknown Role'
        ELSE AW.role
    END AS actor_role,
    (SELECT COUNT(DISTINCT keyword.keyword) 
     FROM movie_keyword
     JOIN keyword ON movie_keyword.keyword_id = keyword.id
     WHERE movie_keyword.movie_id = RM.movie_id) AS keyword_count
FROM 
    RankedMovies RM
LEFT JOIN 
    ActorsWithRoles AW ON RM.movie_id = AW.movie_id
LEFT JOIN 
    PopularMovies PM ON RM.movie_id = PM.movie_id
LEFT JOIN 
    CompanyInfo CI ON RM.movie_id = CI.movie_id
WHERE 
    RM.rn <= 3  -- Limit to top 3 movies per production year
    AND (PM.actor_count IS NOT NULL OR (PM.actor_count IS NULL AND CI.company_name IS NULL))
ORDER BY 
    RM.production_year DESC, RM.movie_title ASC;
