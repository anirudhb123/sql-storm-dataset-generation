WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopRankedMovies AS (
    SELECT 
        title,
        production_year,
        production_companies
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
ActorDetails AS (
    SELECT 
        ka.name,
        ka.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS roles_assigned
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY 
        ka.id, ka.name, ka.person_id
)
SELECT 
    tm.title,
    tm.production_year,
    ad.name AS actor_name,
    ad.movie_count,
    ad.roles_assigned,
    CASE 
        WHEN ad.roles_assigned > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS actor_status,
    COALESCE(STRING_AGG(DISTINCT ct.kind ORDER BY ct.kind), 'No Roles') AS character_types
FROM 
    TopRankedMovies tm
LEFT JOIN 
    ActorDetails ad ON tm.title = ad.movie_id
LEFT JOIN 
    role_type ct ON ad.roles_assigned = ct.id
GROUP BY 
    tm.title, tm.production_year, ad.name, ad.movie_count, ad.roles_assigned
ORDER BY 
    tm.production_year DESC, ad.movie_count DESC;
