WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM title t
    WHERE t.production_year >= 2000
),
actor_movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        m.id AS movie_id,
        m.title
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title m ON ci.movie_id = m.id
),
company_movies AS (
    SELECT 
        cm.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies cm
    JOIN company_name c ON cm.company_id = c.id
    JOIN company_type ct ON cm.company_type_id = ct.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    am.actor_name,
    cm.company_name,
    cm.company_type,
    mk.keyword
FROM ranked_titles rt
JOIN actor_movies am ON rt.title_id = am.movie_id
JOIN company_movies cm ON rt.title_id = cm.movie_id
JOIN movie_keywords mk ON rt.title_id = mk.movie_id
WHERE rt.rank <= 5
ORDER BY rt.production_year DESC, am.actor_name;
