
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT CONCAT(an.name, ' (', rt.role, ')'), ', ') WITHIN GROUP (ORDER BY an.name) AS actor_list
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    COALESCE(ar.actor_count, 0) AS actor_count,
    ar.actor_list
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywordCounts mkc ON rm.title_id = mkc.movie_id
LEFT JOIN 
    ActorRoles ar ON rm.title_id = ar.movie_id
WHERE 
    (rm.rank <= 5 AND rm.production_year >= 2000) OR 
    (ar.actor_count >= 2 AND rm.production_year < 2000)
ORDER BY 
    rm.production_year DESC,
    rm.title;
