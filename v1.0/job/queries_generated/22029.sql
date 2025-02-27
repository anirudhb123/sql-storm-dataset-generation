WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ca.person_id,
        ca.role_id,
        ct.kind AS role_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS actor_count,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ca.person_id) AS rank_within_movie
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ca ON ca.person_id = ci.person_id
    LEFT JOIN 
        comp_cast_type ct ON ct.id = ci.person_role_id
)
SELECT 
    rm.title,
    rm.production_year,
    ar.person_id,
    ar.role_name,
    ar.actor_count,
    (
        SELECT 
            COUNT(*)
        FROM 
            movie_keyword mk
        WHERE 
            mk.movie_id = ar.movie_id
    ) AS keyword_count,
    (
        SELECT 
            STRING_AGG(DISTINCT kn.keyword, ', ')
        FROM 
            movie_keyword mk
        JOIN 
            keyword kn ON kn.id = mk.keyword_id
        WHERE 
            mk.movie_id = ar.movie_id
            AND kn.keyword IS NOT NULL
    ) AS keywords,
    COALESCE(
        (
            SELECT 
                ci.note
            FROM 
                cast_info ci
            WHERE 
                ci.movie_id = ar.movie_id
                AND ci.note IS NOT NULL
            LIMIT 1
        ), 
        'No notes available'
    ) AS note
FROM 
    RankedMovies rm
JOIN 
    ActorRoles ar ON rm.title_id = ar.movie_id
WHERE 
    rm.rn <= 3   -- Only take the most recent 3 titles per production year
    AND ar.actor_count > 2  -- Only include movies with more than 2 actors
ORDER BY 
    rm.production_year DESC, 
    ar.actor_count DESC
LIMIT 100;

This query uses various SQL constructs, including Common Table Expressions (CTEs) to rank movies and capture actor roles, window functions to count actors and rank them, a correlated subquery to count keywords, and string aggregation for joining keywords. Additionally, it incorporates NULL handling to provide defaults where necessary and limits the output to a manageable size while filtering on specified conditions.
