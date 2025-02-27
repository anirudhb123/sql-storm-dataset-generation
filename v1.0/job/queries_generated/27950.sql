WITH MovieData AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        c.role AS actor_role,
        GROUP_CONCAT(k.keyword ORDER BY k.keyword) AS keywords,
        i.info AS additional_info
    FROM 
        title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        info_type i ON mi.info_type_id = i.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
        AND a.name IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year, a.name, a.id, c.role, i.info
),
Ranking AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        actor_name, 
        actor_id, 
        actor_role, 
        keywords, 
        additional_info,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(actor_id) DESC) AS actor_rank
    FROM 
        MovieData
)
SELECT 
    r.production_year,
    r.movie_title,
    r.actor_name,
    r.actor_role,
    r.keywords,
    r.additional_info
FROM 
    Ranking r
WHERE 
    r.actor_rank <= 3
ORDER BY 
    r.production_year, r.actor_rank;
