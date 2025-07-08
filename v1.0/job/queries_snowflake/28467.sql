WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        ROW_NUMBER() OVER (PARTITION BY kt.kind ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),
actor_count AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
company_details AS (
    SELECT 
        cn.name AS company_name,
        COUNT(mc.movie_id) AS movie_count
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    GROUP BY 
        cn.name
    HAVING 
        COUNT(mc.movie_id) > 3
)
SELECT 
    rt.title,
    rt.production_year,
    rt.kind,
    ac.actor_name,
    ac.movie_count AS actor_movie_count,
    cd.company_name,
    cd.movie_count AS company_movie_count
FROM 
    ranked_titles rt
JOIN 
    actor_count ac ON rt.rank = 1
JOIN 
    company_details cd ON cd.movie_count = (SELECT MAX(movie_count) FROM company_details)
WHERE 
    rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, rt.kind, ac.actor_name;

