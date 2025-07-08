
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),

HighRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.actor_name
    FROM 
        RankedTitles rt
    WHERE 
        rt.year_rank <= 5
)

SELECT 
    hrt.title AS Movie_Title,
    hrt.production_year AS Release_Year,
    LISTAGG(hrt.actor_name, ', ') WITHIN GROUP (ORDER BY hrt.actor_name) AS Leading_Actors
FROM 
    HighRankedTitles hrt
GROUP BY 
    hrt.title_id, hrt.title, hrt.production_year
ORDER BY 
    hrt.production_year DESC;
