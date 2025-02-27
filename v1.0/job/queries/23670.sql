WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        at.kind_id,
        RANK() OVER (PARTITION BY at.kind_id ORDER BY at.production_year DESC) AS rank
    FROM 
        aka_title AS at
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        count(DISTINCT ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS r ON ci.role_id = r.id
    WHERE 
        ci.nr_order < 5 
    GROUP BY 
        ci.person_id
),
CoActors AS (
    SELECT 
        ci1.person_id AS actor_id,
        count(DISTINCT ci2.person_id) AS co_actor_count
    FROM 
        cast_info AS ci1
    JOIN 
        cast_info AS ci2 ON ci1.movie_id = ci2.movie_id AND ci1.person_id <> ci2.person_id
    GROUP BY 
        ci1.person_id
),
FilteredMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        ar.total_movies,
        ar.roles,
        ca.co_actor_count
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        ActorRoles AS ar ON rm.title_id = ar.person_id
    LEFT JOIN 
        CoActors AS ca ON ar.person_id = ca.actor_id
    WHERE 
        rm.rank <= 3
        AND (ca.co_actor_count IS NULL OR ca.co_actor_count > 10)
)
SELECT 
    DISTINCT fm.title,
    fm.production_year,
    fm.kind_id,
    fm.total_movies,
    fm.roles
FROM 
    FilteredMovies AS fm
WHERE 
    EXISTS (
        SELECT 
            1
        FROM 
            movie_keyword AS mk 
        WHERE 
            mk.movie_id = fm.title_id
            AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')
    )
ORDER BY 
    fm.production_year DESC,
    fm.kind_id;
