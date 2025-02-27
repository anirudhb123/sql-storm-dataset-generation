WITH movie_data AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
actor_data AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        p.info AS actor_info,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    GROUP BY 
        a.id, a.name, p.info
),
company_data AS (
    SELECT 
        c.id AS company_id,
        c.name AS company_name,
        COUNT(m.id) AS movies_count
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        title m ON mc.movie_id = m.id
    WHERE 
        c.country_code = 'USA'
    GROUP BY 
        c.id, c.name
)
SELECT 
    md.movie_title,
    md.production_year,
    ad.actor_name,
    ad.movie_count,
    cd.company_name,
    cd.movies_count
FROM 
    movie_data md
JOIN 
    cast_info ci ON md.title_id = ci.movie_id
JOIN 
    aka_name ad ON ci.person_id = ad.person_id
JOIN 
    movie_companies mc ON md.title_id = mc.movie_id
JOIN 
    company_name cd ON mc.company_id = cd.id
WHERE 
    ad.actor_name LIKE '%Smith%'  -- Example of string processing filtering
ORDER BY 
    md.production_year DESC, ad.movie_count DESC;
