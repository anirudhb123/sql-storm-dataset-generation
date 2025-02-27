WITH title_info AS (
    SELECT
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id, t.title, t.production_year
),
actor_info AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT t.movie_title, ', ') AS movies,
        STRING_AGG(DISTINCT c.role_id::text, ', ') AS role_ids,
        COUNT(DISTINCT t.id) AS total_movies
    FROM
        aka_name a
    LEFT JOIN
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN
        title_info t ON ci.movie_id = t.title_id
    LEFT JOIN
        role_type c ON ci.role_id = c.id
    GROUP BY
        a.id, a.name
),
company_info AS (
    SELECT
        c.id AS company_id,
        c.name AS company_name,
        STRING_AGG(DISTINCT mt.movie_id::text, ', ') AS movie_ids
    FROM
        company_name c
    LEFT JOIN
        movie_companies mt ON c.id = mt.company_id
    GROUP BY
        c.id, c.name
)
SELECT 
    a.actor_id,
    a.actor_name,
    a.movies,
    a.total_movies,
    c.company_id,
    c.company_name,
    STRING_AGG(DISTINCT t.production_year::text, ', ') AS production_years,
    STRING_AGG(DISTINCT ti.keywords, ', ') AS all_keywords
FROM 
    actor_info a
LEFT JOIN
    movie_companies mc ON mc.movie_id IN (SELECT t.id FROM title_info ti WHERE a.movies LIKE '%' || ti.movie_title || '%')
LEFT JOIN 
    company_info c ON mc.company_id = c.company_id
LEFT JOIN 
    title_info ti ON ti.title_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = a.actor_id)
GROUP BY 
    a.actor_id, 
    a.actor_name, 
    c.company_id, 
    c.company_name
ORDER BY 
    a.total_movies DESC, 
    a.actor_name;
