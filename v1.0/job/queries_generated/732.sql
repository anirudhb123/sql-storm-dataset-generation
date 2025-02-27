WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) OVER (PARTITION BY title.id) AS total_cast,
        SUM(CASE WHEN roles.role = 'actor' THEN 1 ELSE 0 END) OVER (PARTITION BY title.id) AS actor_count
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    LEFT JOIN 
        role_type roles ON cast_info.role_id = roles.id
    WHERE 
        title.production_year >= 2000
),
ActorNames AS (
    SELECT 
        aka_name.person_id,
        STRING_AGG(aka_name.name, ', ') AS all_names
    FROM 
        aka_name
    GROUP BY 
        aka_name.person_id
),
IndustryPlayers AS (
    SELECT
        company_name.name AS company_name,
        COUNT(movie_companies.movie_id) AS movie_count
    FROM 
        company_name
    JOIN 
        movie_companies ON company_name.id = movie_companies.company_id
    WHERE 
        company_name.country_code IS NOT NULL
    GROUP BY 
        company_name.name
    HAVING 
        COUNT(movie_companies.movie_id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.actor_count,
    an.all_names,
    ip.company_name,
    ip.movie_count
FROM 
    RankedMovies rm
JOIN 
    ActorNames an ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = an.person_id)
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    IndustryPlayers ip ON mc.company_id = (SELECT id FROM company_name WHERE name = ip.company_name LIMIT 1)
WHERE 
    rm.actor_count > 10
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
