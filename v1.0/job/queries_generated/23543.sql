WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
),
actor_movies AS (
    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        COALESCE(k.keyword, 'No Keywords') AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS movie_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
company_movies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) OVER (PARTITION BY m.movie_id) AS num_companies
    FROM movie_companies m
    JOIN company_name c ON m.company_id = c.id
    JOIN company_type ct ON m.company_type_id = ct.id
),
movie_details AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        am.actor_name,
        cm.company_name,
        cm.company_type,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = rt.title_id) AS total_cast_count
    FROM ranked_titles rt
    LEFT JOIN actor_movies am ON rt.title_id = am.movie_id
    LEFT JOIN company_movies cm ON rt.title_id = cm.movie_id
    WHERE rt.production_year > 2000
      AND (cm.company_name IS NOT NULL OR am.actor_name IS NOT NULL)
)
SELECT 
    md.title AS Movie_Title,
    md.production_year AS Production_Year,
    md.actor_name AS Actor_Name,
    md.company_name AS Production_Company,
    md.company_type AS Company_Type,
    md.total_cast_count AS Cast_Count
FROM movie_details md
WHERE md.actor_name IS NOT NULL
   OR (md.company_name IS NULL AND md.production_year = 2020)
ORDER BY md.production_year DESC, md.title;
