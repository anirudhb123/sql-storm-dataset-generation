WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE NULL END), 0) AS avg_cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.avg_cast_count,
        md.keyword_count,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.avg_cast_count DESC) AS rank_within_year
    FROM 
        MovieDetails md
    WHERE 
        md.keyword_count > 2
),
ActorsWithMultipleRoles AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        COUNT(DISTINCT ci.role_id) AS role_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ak.id, ak.name
    HAVING 
        role_count > 1
)
SELECT 
    pm.title,
    pm.production_year,
    pm.avg_cast_count,
    pm.keyword_count,
    awmr.actor_id,
    awmr.name AS actor_name,
    awmr.role_count,
    awmr.roles
FROM 
    PopularMovies pm
LEFT JOIN 
    ActorsWithMultipleRoles awmr ON pm.avg_cast_count > (SELECT AVG(avg_cast_count) FROM MovieDetails)
WHERE 
    pm.rank_within_year <= 5
ORDER BY 
    pm.production_year DESC, pm.avg_cast_count DESC;
