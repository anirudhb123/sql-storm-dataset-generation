
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        (SELECT mc.movie_id, a.name
         FROM movie_companies mc
         JOIN company_name a ON mc.company_id = a.id
         WHERE mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')) AS a ON a.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(ci.nr_order) AS max_role_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.director_name,
    cd.actor_count,
    cd.max_role_order,
    md.keywords
FROM 
    movie_details md
JOIN 
    cast_details cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, cd.actor_count DESC;
