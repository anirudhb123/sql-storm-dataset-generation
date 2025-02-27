WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),

FilteredTitles AS (
    SELECT
        rt.aka_id,
        rt.aka_name,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rn <= 3  -- Get top 3 recent titles per person
),

ActorInfo AS (
    SELECT
        p.id AS person_id,
        p.name AS actor_name,
        ft.aka_name,
        ft.title,
        ft.production_year
    FROM 
        name p
    LEFT JOIN 
        FilteredTitles ft ON p.id = ft.aka_id
    WHERE 
        p.gender = 'M'  -- Filter for male actors
)

SELECT 
    ai.actor_name,
    COUNT(ft.title) AS num_titles,
    ARRAY_AGG(ft.title) AS titles,
    MIN(ft.production_year) AS first_year,
    MAX(ft.production_year) AS last_year
FROM 
    ActorInfo ai
LEFT JOIN 
    FilteredTitles ft ON ai.aka_name = ft.aka_name
GROUP BY 
    ai.actor_name
ORDER BY 
    num_titles DESC
LIMIT 10; -- Show top 10 actors with the most titles
