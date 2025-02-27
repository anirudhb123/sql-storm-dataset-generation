WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY LENGTH(at.title) DESC) AS title_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
TopTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.actor_name
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 5
), 
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_titles
    FROM 
        TopTitles
    GROUP BY 
        actor_name
)
SELECT 
    tc.title,
    tc.production_year,
    ac.actor_name,
    ac.total_titles
FROM 
    TopTitles tc
LEFT JOIN 
    ActorCount ac ON tc.actor_name = ac.actor_name
ORDER BY 
    total_titles DESC, production_year DESC;