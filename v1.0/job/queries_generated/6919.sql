WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        ak.name AS actor_name,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, ak.name, c.kind
    ORDER BY 
        t.production_year DESC, t.title
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.company_type,
    md.keywords
FROM 
    movie_details md
WHERE 
    md.keywords LIKE '%action%'
LIMIT 100;
