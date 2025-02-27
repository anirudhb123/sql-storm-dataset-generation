WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.kind_id IN (
            SELECT id FROM kind_type WHERE kind IN ('movie', 'tv')
        )
        AND t.production_year > 2000
),

ActorAssociations AS (
    SELECT 
        r.actor_id,
        COUNT(DISTINCT t.id) AS movie_count,
        STRING_AGG(DISTINCT t.movie_title, ', ') AS movie_titles
    FROM 
        RankedTitles r
    JOIN 
        aka_title t ON r.movie_title = t.title
    GROUP BY 
        r.actor_id
),

ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        CASE 
            WHEN ai.info IS NOT NULL THEN ai.info 
            ELSE 'N/A' 
        END AS bio_information
    FROM 
        aka_name a
    LEFT JOIN 
        person_info ai ON a.person_id = ai.person_id AND ai.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
)

SELECT 
    ai.actor_name,
    ai.bio_information,
    aa.movie_count,
    aa.movie_titles
FROM 
    ActorInfo ai
JOIN 
    ActorAssociations aa ON ai.actor_id = aa.actor_id
WHERE 
    aa.movie_count > 5
ORDER BY 
    aa.movie_count DESC, ai.actor_name;
