WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS alternative_titles,
        STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies,
        STRING_AGG(DISTINCT pt.role, ', ') AS cast_roles
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON ak.person_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        role_type pt ON ci.role_id = pt.id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
    ORDER BY 
        t.production_year DESC
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.kind_id,
    COALESCE(md.alternative_titles, 'No alternative titles') AS alternative_titles,
    COALESCE(md.keywords, 'No keywords assigned') AS keywords,
    COALESCE(md.production_companies, 'No production companies') AS production_companies,
    COALESCE(md.cast_roles, 'No cast information') AS cast_roles
FROM 
    movie_details md
WHERE 
    md.production_year >= 2010
ORDER BY 
    md.production_year DESC, md.movie_title;
