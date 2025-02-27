WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS roles_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(arc.actor_count, 0) AS actor_count,
    COALESCE(arc.roles_count, 0) AS roles_count,
    COALESCE(mkw.keywords, '{}') AS keywords,
    CASE 
        WHEN arc.actor_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoleCounts arc ON rm.movie_id = arc.movie_id
LEFT JOIN 
    MoviesWithKeywords mkw ON rm.movie_id = mkw.movie_id
WHERE 
    rm.title_rank <= 10
ORDER BY 
    rm.production_year DESC,
    rm.title;
