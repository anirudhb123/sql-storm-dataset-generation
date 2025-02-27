WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        MAX(mi.info) AS movie_info
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    GROUP BY 
        t.id
),

RankedActors AS (
    SELECT 
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ak.id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.actor_names,
    ra.actor_name,
    ra.movie_count,
    rkp.kind AS role_type
FROM 
    RankedMovies rm
JOIN 
    RankedActors ra ON rm.actor_names LIKE '%' || ra.actor_name || '%'
JOIN 
    cast_info c ON c.person_id = ra.actor_id AND c.movie_id = rm.movie_id
JOIN 
    role_type rkp ON c.role_id = rkp.id
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
