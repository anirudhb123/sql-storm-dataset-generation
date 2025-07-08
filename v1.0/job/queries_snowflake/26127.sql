WITH ranked_titles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
),
actor_details AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
),
movie_company_info AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY ct.kind) AS company_rank
    FROM movie_companies m
    JOIN company_name c ON m.company_id = c.id
    JOIN company_type ct ON m.company_type_id = ct.id
)
SELECT 
    rt.movie_title,
    rt.production_year,
    rt.keyword,
    ad.actor_name,
    mc.company_name,
    mc.company_type
FROM ranked_titles rt
JOIN actor_details ad ON rt.production_year = ad.movie_id
JOIN movie_company_info mc ON rt.production_year = mc.movie_id
WHERE rt.title_rank = 1 AND ad.actor_rank = 1 AND mc.company_rank = 1
ORDER BY rt.production_year DESC, rt.movie_title;
