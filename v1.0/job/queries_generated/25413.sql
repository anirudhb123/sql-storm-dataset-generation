WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actors_with_movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS movie_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
),
company_movie_info AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    am.actor_name,
    am.movie_order,
    cmi.companies,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    ranked_titles rt
JOIN 
    actors_with_movies am ON rt.title_id = am.movie_id
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    company_movie_info cmi ON rt.title_id = cmi.movie_id
WHERE 
    rt.title_rank <= 10
GROUP BY 
    rt.title, rt.production_year, am.actor_name, am.movie_order, cmi.companies
ORDER BY 
    rt.production_year DESC, rt.title;
