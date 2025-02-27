WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name SEPARATOR ', ') AS company_names,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS actors
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.imdb_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        pi.info AS actor_info
    FROM 
        aka_name a
    JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    md.company_names,
    GROUP_CONCAT(DISTINCT ai.name ORDER BY ai.name SEPARATOR ', ') AS associated_actors,
    COUNT(DISTINCT ai.actor_info) AS info_count
FROM 
    movie_details md
LEFT JOIN 
    actor_info ai ON FIND_IN_SET(ai.name, md.actors) > 0
GROUP BY 
    md.movie_id, md.movie_title, md.production_year, md.movie_keyword, md.company_names
ORDER BY 
    md.production_year DESC, md.movie_title;
