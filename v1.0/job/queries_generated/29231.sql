WITH movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ak.name AS aka_name,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keywords mw ON t.id = mw.movie_id
    GROUP BY 
        t.id, ak.name, t.production_year
), 
person_roles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT CONCAT(p.name, ' as ', rt.role), ', ') AS cast
    FROM 
        cast_info ci
    JOIN 
        name p ON ci.person_id = p.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.aka_name,
    md.company_names,
    md.movie_keywords,
    pr.cast
FROM 
    movie_details md
LEFT JOIN 
    person_roles pr ON md.title_id = pr.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
