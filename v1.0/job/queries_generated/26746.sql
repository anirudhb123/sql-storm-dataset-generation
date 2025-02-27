WITH filtered_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        k.keyword,
        s.name AS studio_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name s ON mc.company_id = s.id
    WHERE 
        t.production_year >= 2000 
        AND k.keyword ILIKE '%drama%'
),
detailed_cast AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        r.role,
        r.gender
    FROM 
        cast_info c
    JOIN 
        name p ON c.person_id = p.imdb_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role ILIKE '%lead%'
),
aggregated_data AS (
    SELECT 
        ft.title,
        ft.production_year,
        ft.keyword,
        ft.studio_name,
        COUNT(dc.actor_name) AS lead_actor_count
    FROM 
        filtered_titles ft
    LEFT JOIN 
        detailed_cast dc ON ft.title_id = dc.movie_id
    GROUP BY 
        ft.title, ft.production_year, ft.keyword, ft.studio_name
)
SELECT 
    ad.title,
    ad.production_year,
    ad.keyword,
    ad.studio_name,
    ad.lead_actor_count
FROM 
    aggregated_data ad
WHERE 
    ad.lead_actor_count > 0
ORDER BY 
    ad.production_year DESC, ad.title;
