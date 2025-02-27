
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_details AS (
    SELECT 
        c.id AS person_id,
        c.name,
        STRING_AGG(DISTINCT t.title, ', ') AS movies,
        COUNT(DISTINCT t.id) AS movie_count
    FROM 
        aka_name c
    JOIN 
        cast_info ci ON c.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        c.id, c.name
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_names,
    md.keywords,
    ad.movie_count AS actor_count,
    ci.companies,
    ci.company_types
FROM 
    movie_details md
LEFT JOIN 
    actor_details ad ON ad.movies LIKE '%' || md.title || '%'
LEFT JOIN 
    company_info ci ON ci.movie_id = md.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
