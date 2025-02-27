WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ca.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        cast_info ca ON ca.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ca.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genres')
        AND mi.info ILIKE '%Drama%'
),
title_with_company AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.actor_name,
        mc.note AS company_note
    FROM 
        ranked_titles rt
    JOIN 
        movie_companies mc ON mc.movie_id = rt.title_id
)

SELECT 
    twc.title,
    twc.production_year,
    STRING_AGG(twc.actor_name, ', ') AS actor_list,
    COUNT(DISTINCT tc.kind) AS distinct_company_types,
    STRING_AGG(DISTINCT twc.company_note, '; ') AS company_notes
FROM 
    title_with_company twc
JOIN 
    company_type tc ON tc.id IN (SELECT company_type_id FROM movie_companies WHERE movie_id = twc.title_id)
GROUP BY 
    twc.title, twc.production_year
ORDER BY 
    twc.production_year DESC;
