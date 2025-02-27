WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_actor_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
HighlyRatedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        CASE 
            WHEN AVG(mi.info::float) IS NULL THEN 'No Rating'
            ELSE AVG(mi.info::float)::TEXT
        END AS average_rating
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (
            SELECT id FROM info_type WHERE info = 'rating'
        )
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
ActorsWithMultipleRoles AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        COUNT(DISTINCT ci.role_id) AS roles_count
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    GROUP BY 
        p.id, p.name
    HAVING 
        COUNT(DISTINCT ci.role_id) > 1
),
ComplexReport AS (
    SELECT 
        mh.movie_title,
        mh.production_year,
        mh.average_rating,
        ra.actor_count,
        ar.actor_name,
        COALESCE(ar.roles_count, 0) AS roles_count
    FROM 
        HighlyRatedMovies mh
    JOIN 
        RankedMovies ra ON mh.production_year = ra.production_year 
    LEFT JOIN 
        ActorsWithMultipleRoles ar ON ra.rank_by_actor_count = ar.roles_count
    WHERE 
        mh.average_rating != 'No Rating'
)
SELECT 
    movie_title,
    production_year,
    average_rating,
    actor_count,
    actor_name,
    roles_count
FROM 
    ComplexReport
ORDER BY 
    production_year DESC, actor_count DESC;
