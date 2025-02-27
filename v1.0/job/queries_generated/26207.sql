WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT cc.person_id) AS cast_ids,
        GROUP_CONCAT(DISTINCT a.name) AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_type c ON c.id = mc.company_type_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    WHERE 
        t.production_year > 1990
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        GROUP_CONCAT(DISTINCT ci.movie_id) AS movie_ids
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON ci.person_id = a.person_id
    GROUP BY 
        a.id, a.name
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.company_type,
    ad.name AS actor_name,
    ad.movie_ids
FROM 
    movie_details md
JOIN 
    actor_details ad ON FIND_IN_SET(ad.actor_id, md.cast_ids) > 0
ORDER BY 
    md.production_year DESC, md.title;
