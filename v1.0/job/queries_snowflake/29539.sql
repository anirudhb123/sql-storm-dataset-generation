
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND c.country_code = 'USA'
),
actor_details AS (
    SELECT 
        a.name AS actor_name,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movies_starred
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        a.name
),
company_count AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        movie_id
)
SELECT 
    md.title,
    md.production_year,
    ad.actor_name,
    ad.movies_starred,
    md.company_name,
    cc.company_count
FROM 
    movie_details md
JOIN 
    actor_details ad ON md.movie_id IN (
        SELECT movie_id 
        FROM cast_info 
        WHERE person_id IN (SELECT person_id FROM aka_name WHERE name = ad.actor_name)
    )
JOIN 
    company_count cc ON md.movie_id = cc.movie_id
ORDER BY 
    md.production_year DESC, md.title;
