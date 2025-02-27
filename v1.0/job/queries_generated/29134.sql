WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS role_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COALESCE(m.info, 'No info available') AS movie_info
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.id = cc.subject_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type c ON c.id = ci.role_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_info m ON m.movie_id = t.id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    WHERE 
        t.production_year >= 1990 
        AND EXISTS (SELECT 1 FROM company_name cn JOIN movie_companies mc ON mc.movie_id = t.id WHERE cn.id = mc.company_id AND cn.country_code = 'USA')
    GROUP BY 
        t.id, t.title, t.production_year, a.name, c.kind, m.info
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    role_type,
    keywords,
    movie_info
FROM 
    MovieData
ORDER BY 
    production_year DESC, title;
