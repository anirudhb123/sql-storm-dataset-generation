WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn_year,
        COUNT(*) OVER (PARTITION BY a.production_year) AS movie_count
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, ak.name, r.role
),
AliveDirectors AS (
    SELECT 
        DISTINCT m.id,
        m.title,
        com.name AS company_name,
        c.note AS company_note
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name com ON mc.company_id = com.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
    WHERE 
        com.country_code = 'USA'
        AND mi.info IS NOT NULL
),
ComplexMovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT c.person_id) AS unique_actors
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id
)
SELECT 
    rm.production_year,
    rm.title,
    rm.movie_count,
    ar.actor_name,
    ar.role_name,
    ci.company_name,
    ci.company_note,
    CASE 
        WHEN cm.unique_actors > 10 THEN 'Epic'
        WHEN cm.unique_actors BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Minimal' 
    END AS actor_diversity,
    COALESCE(SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS valid_company_notes,
    (SELECT COUNT(*) FROM alive_directors WHERE m.id = movie_id) AS director_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    AliveDirectors ci ON rm.movie_id = ci.id
LEFT JOIN 
    ComplexMovieInfo cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rn_year <= 5
    AND (ar.actor_name IS NOT NULL OR ci.company_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, actor_diversity DESC;

