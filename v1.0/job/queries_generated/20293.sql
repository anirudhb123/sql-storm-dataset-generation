WITH MovieCTE AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        AVG(CASE 
                WHEN role_type.role IS NULL THEN 0 ELSE 1 
            END) AS actor_ratio
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    LEFT JOIN 
        role_type ON cast_info.role_id = role_type.id 
    WHERE 
        title.production_year > 2000
    GROUP BY 
        title.id, title.title, title.production_year
),

CompanyCTE AS (
    SELECT 
        movie_companies.movie_id,
        GROUP_CONCAT(DISTINCT company_name.name || ' (' || company_type.kind || ')') AS companies,
        COUNT(DISTINCT company_name.id) AS total_companies
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        company_type ON movie_companies.company_type_id = company_type.id 
    GROUP BY 
        movie_companies.movie_id
),

RankedMovies AS (
    SELECT 
        M.movie_id,
        M.title,
        M.production_year,
        M.total_cast,
        M.actor_ratio,
        C.companies,
        C.total_companies,
        ROW_NUMBER() OVER (ORDER BY M.total_cast DESC, M.production_year DESC) AS movie_rank
    FROM 
        MovieCTE M
    JOIN 
        CompanyCTE C ON M.movie_id = C.movie_id
)

SELECT 
    R.movie_id,
    R.title,
    R.production_year,
    R.total_cast,
    R.actor_ratio,
    R.companies,
    R.total_companies,
    CASE 
        WHEN R.actor_ratio > 0.5 THEN 'High Actor Ratio' 
        ELSE 'Low Actor Ratio' 
    END AS actor_ratio_category,
    COALESCE(JSON_Build_Object('rank', R.movie_rank), 'No Rank') AS rank_info
FROM 
    RankedMovies R
WHERE 
    R.total_companies > 0 
ORDER BY 
    actor_ratio_category DESC, 
    R.production_year DESC;

-- Note: Usage of COALESCE with JSON_Build_Object to return a nested object
-- based on the rank information, showcasing a kind of unusual semantics
