WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),

ActorCount AS (
    SELECT 
        actor_name, 
        COUNT(DISTINCT title_id) AS title_count
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
    GROUP BY 
        actor_name
),

HighlightedTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        ac.actor_name,
        ac.title_count,
        ROW_NUMBER() OVER (ORDER BY ac.title_count DESC) AS title_rank
    FROM 
        RankedTitles rt
    JOIN 
        ActorCount ac ON rt.actor_name = ac.actor_name
    WHERE 
        rt.rank <= 5
)

SELECT 
    ht.title,
    ht.production_year,
    ht.actor_name,
    ht.title_count
FROM 
    HighlightedTitles ht
WHERE 
    ht.title_rank <= 10
ORDER BY 
    ht.title_count DESC, 
    ht.production_year DESC;
