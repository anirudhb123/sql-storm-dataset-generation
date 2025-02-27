WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) >= 3
),
HighRatedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        mi.info AS rating,
        RANK() OVER (ORDER BY mi.info DESC) AS rating_rank
    FROM 
        title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id 
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
)
SELECT 
    rn.movie_id,
    rn.movie_title,
    rn.production_year,
    ar.person_id,
    ar.movie_count,
    ar.roles,
    hr.rating,
    hr.rating_rank
FROM 
    RankedMovies rn
LEFT JOIN 
    ActorRoles ar ON ar.movie_count >= 3 
LEFT JOIN 
    HighRatedMovies hr ON rn.movie_id = hr.movie_id
WHERE 
    rn.title_rank <= 5 AND
    (hr.rating_rank IS NULL OR hr.rating < '7.0')
ORDER BY 
    rn.production_year DESC, 
    rn.title_rank, 
    ar.movie_count DESC NULLS LAST;
