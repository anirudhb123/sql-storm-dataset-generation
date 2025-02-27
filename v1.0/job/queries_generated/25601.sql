WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.kind AS company_kind,
        a.name AS actor_name,
        p.gender AS actor_gender,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT i.info) AS info
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.person_id
    JOIN 
        name p ON a.person_id = p.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type i ON mi.info_type_id = i.id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind, a.name, p.gender
)

SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    actor_gender,
    REPLACE(REPLACE(REPLACE(keywords, ',', ' | '), NULL, ''), 'NULL', 'N/A') AS formatted_keywords,
    info 
FROM 
    movie_details
WHERE 
    production_year >= 2000 AND 
    actor_gender = 'F'
ORDER BY 
    production_year DESC;
