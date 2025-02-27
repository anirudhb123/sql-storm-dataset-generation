WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS cast_type,
        a.name AS actor_name,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT ci.nr_order || ': ' || a.name) AS full_cast
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind, a.name, k.keyword
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_type,
    md.full_cast,
    COUNT(mk.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    movie_details md
LEFT JOIN 
    movie_keyword mk ON md.movie_title = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    md.production_year >= 2000
GROUP BY 
    md.movie_title, md.production_year, md.cast_type, md.full_cast
ORDER BY 
    md.production_year DESC, md.movie_title;
