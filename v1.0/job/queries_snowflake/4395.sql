
WITH MovieRoles AS (
    SELECT 
        ci.movie_id, 
        r.role AS role_name, 
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
CompleteMovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mr.actor_count, 0) AS actor_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        MovieRoles mr ON mt.id = mr.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year IS NOT NULL
)
SELECT 
    cm.title,
    cm.production_year,
    cm.actor_count,
    ROW_NUMBER() OVER (PARTITION BY cm.production_year ORDER BY cm.actor_count DESC) AS rank_within_year,
    CASE 
        WHEN cm.actor_count > (SELECT AVG(actor_count) FROM CompleteMovieInfo) THEN 'Above Average'
        ELSE 'Below Average'
    END AS actor_performance,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = cm.movie_id) AS total_complete_cast
FROM 
    CompleteMovieInfo cm
WHERE 
    cm.actor_count > 0 
ORDER BY 
    cm.production_year, 
    cm.actor_count DESC;
