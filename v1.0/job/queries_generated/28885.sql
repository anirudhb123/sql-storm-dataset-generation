WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword_id) AS keyword_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kc.keyword_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, t.title, t.production_year
),

actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notable_roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),

company_movies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)

SELECT 
    rt.title,
    rt.production_year,
    rt.keyword_count,
    ai.name AS actor_name,
    ai.movies_count AS actor_movie_count,
    ai.notable_roles,
    cm.company_name,
    cm.company_type,
    cm.total_movies
FROM 
    ranked_titles rt
LEFT JOIN 
    actor_info ai ON rt.title_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name WHERE name ILIKE 'John%'))
LEFT JOIN 
    company_movies cm ON rt.title_id = cm.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC, rt.keyword_count DESC, ai.movies_count DESC;
