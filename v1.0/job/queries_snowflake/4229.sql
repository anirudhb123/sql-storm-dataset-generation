
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie'))
    GROUP BY 
        t.id, t.title, t.production_year
),
company_details AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
    GROUP BY 
        m.movie_id
),
keyword_details AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    COALESCE(md.actor_names, 'No actors listed') AS actor_names,
    COALESCE(cd.company_count, 0) AS company_count,
    COALESCE(cd.company_names, 'No companies listed') AS company_names,
    COALESCE(kd.keywords, 'No keywords') AS keywords
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    keyword_details kd ON md.movie_id = kd.movie_id
WHERE 
    md.actor_count > 0
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 100;
