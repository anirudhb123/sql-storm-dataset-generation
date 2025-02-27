WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY RANDOM()) AS randomized_order
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorRolesCTE AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_name,
        COALESCE(char_n.name, 'Unknown Character') AS character_name,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN char_name char_n ON ci.person_role_id = char_n.id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY 
        a.name, c.movie_id, r.role, char_n.name
),
MovieKeywordsCTE AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
FinalReport AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        ar.actor_name,
        ar.role_name,
        ar.character_name,
        ar.role_count,
        mk.keywords,
        RANK() OVER (PARTITION BY rm.production_year ORDER BY ar.role_count DESC) AS actor_rank
    FROM 
        RecursiveMovieCTE rm
    LEFT JOIN ActorRolesCTE ar ON rm.movie_id = ar.movie_id
    LEFT JOIN MovieKeywordsCTE mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.randomized_order <= 10 
        AND (ar.role_count IS NULL OR ar.role_count > 0)
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    COUNT(DISTINCT actor_name) AS total_actors,
    COUNT(DISTINCT role_name) AS unique_roles,
    MAX(actor_rank) AS highest_actor_rank,
    STRING_AGG(DISTINCT keywords, ', ') AS all_keywords
FROM 
    FinalReport
GROUP BY 
    movie_id, movie_title, production_year
HAVING 
    COUNT(DISTINCT role_name) > 2
ORDER BY 
    production_year DESC, total_actors DESC;
