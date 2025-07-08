
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM
        aka_title mt
    JOIN
        complete_cast cc ON mt.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
ActorRoles AS (
    SELECT 
        ai.person_id,
        MIN(ri.role) AS primary_role
    FROM 
        aka_name ai
    JOIN 
        cast_info ci ON ai.person_id = ci.person_id
    JOIN 
        role_type ri ON ci.role_id = ri.id
    GROUP BY 
        ai.person_id
)
SELECT 
    mv.movie_id,
    mv.title,
    mv.production_year,
    mk.keywords,
    COALESCE(ar.primary_role, 'Unknown') AS primary_actor_role,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    SUM(CASE 
            WHEN ci.note IS NOT NULL THEN 1 
            ELSE 0 
        END) AS cast_with_notes,
    CASE 
        WHEN mv.rank_by_cast <= 5 THEN 'Top 5 Cast'
        WHEN mv.rank_by_cast <= 10 THEN 'Top 10 Cast'
        ELSE 'Below Top 10 Cast'
    END AS cast_rank_category
FROM 
    RankedMovies mv
LEFT JOIN 
    MovieKeywords mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    ActorRoles ar ON ci.person_id = ar.person_id
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, mk.keywords, ar.primary_role, mv.rank_by_cast
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    mv.production_year DESC, mv.title;
