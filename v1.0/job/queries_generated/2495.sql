WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rnk
    FROM title
    WHERE title.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        aka_name.person_id,
        aka_name.name AS actor_name,
        role_type.role,
        COUNT(DISTINCT cast_info.movie_id) AS movie_count
    FROM aka_name
    JOIN cast_info ON aka_name.person_id = cast_info.person_id
    JOIN role_type ON cast_info.role_id = role_type.id
    GROUP BY aka_name.person_id, aka_name.name, role_type.role
),
MoviesWithCompanyInfo AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        COUNT(DISTINCT movie_companies.company_id) AS company_count,
        MAX(CASE WHEN company_name.name IS NOT NULL THEN company_name.name ELSE 'Unknown' END) AS company_name
    FROM title
    LEFT JOIN movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN company_name ON movie_companies.company_id = company_name.id
    GROUP BY title.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ar.actor_name, 'No Actors Found') AS primary_actor,
    COALESCE(ar.role, 'N/A') AS primary_role,
    mwc.company_count,
    mwc.company_name
FROM RankedMovies rm
LEFT JOIN ActorRoles ar ON rm.movie_id = ar.movie_count
LEFT JOIN MoviesWithCompanyInfo mwc ON rm.movie_id = mwc.movie_id
WHERE rm.rnk <= 10
ORDER BY rm.production_year DESC, rm.title ASC;
