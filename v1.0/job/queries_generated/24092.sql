WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rank_per_year
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
DistinctActors AS (
    SELECT 
        aka_name.person_id,
        string_agg(DISTINCT aka_name.name, ', ') AS actor_names
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    GROUP BY 
        aka_name.person_id
),
MovieCompaniesAggregate AS (
    SELECT 
        movie_companies.movie_id,
        COUNT(DISTINCT company_name.name) AS company_count,
        COUNT(DISTINCT CASE WHEN company_type.kind = 'Distributor' THEN company_name.name END) AS distributor_count,
        COUNT(DISTINCT CASE WHEN company_type.kind = 'Production' THEN company_name.name END) AS production_count
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        company_type ON movie_companies.company_type_id = company_type.id
    GROUP BY 
        movie_companies.movie_id
)
SELECT 
    R.movie_id,
    R.title,
    R.production_year,
    COALESCE(A.actor_names, 'Unknown Actors') AS actor_names,
    M.company_count,
    M.distributor_count,
    M.production_count
FROM 
    RankedMovies R
LEFT JOIN 
    DistinctActors A ON R.movie_id = (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name WHERE aka_name.name = ANY(string_to_array(A.actor_names, ', '))) LIMIT 1)
LEFT JOIN 
    MovieCompaniesAggregate M ON R.movie_id = M.movie_id
WHERE 
    R.rank_per_year <= 5 
    AND (M.company_count > 1 OR M.distributor_count IS NOT NULL)
ORDER BY 
    R.production_year DESC, R.title;

-- This query attempts to extract detailed information about the top 5 movies per year,
-- including the names of distinct actors involved, and an aggregation of the companies tied 
-- to each movie while ensuring to highlight corner cases such as null values and distinct counts.
