WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'plot')
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE phonetic_code IS NOT NULL)
),

AggregatedData AS (
    SELECT 
        rt.production_year,
        COUNT(*) AS total_titles,
        STRING_AGG(DISTINCT rt.title, ', ') AS titles,
        STRING_AGG(DISTINCT rt.actor_name, ', ') AS actors
    FROM 
        RankedTitles rt
    GROUP BY 
        rt.production_year
)

SELECT 
    ad.production_year,
    ad.total_titles,
    ad.titles,
    ad.actors,
    ARRAY_AGG(DISTINCT CONCAT(c.role_id, ': ', c.note)) AS role_details
FROM 
    AggregatedData ad
LEFT JOIN 
    cast_info c ON ad.production_year = (SELECT production_year FROM aka_title WHERE id = c.movie_id LIMIT 1)
GROUP BY 
    ad.production_year, ad.total_titles, ad.titles, ad.actors
ORDER BY 
    ad.production_year DESC;
