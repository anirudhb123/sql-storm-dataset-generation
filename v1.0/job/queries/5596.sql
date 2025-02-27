
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_info AS (
    SELECT 
        a.person_id,
        a.name,
        pi.info AS biography
    FROM 
        aka_name a
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Biography'
        )
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    md.cast_count,
    ai.name AS actor_name,
    ai.biography
FROM 
    movie_details md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    actor_info ai ON ci.person_id = ai.person_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title;
