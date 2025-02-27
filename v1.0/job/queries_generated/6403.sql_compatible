
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
person_details AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        STRING_AGG(DISTINCT p.info, ', ') AS info
    FROM 
        aka_name a
    JOIN 
        person_info p ON a.person_id = p.person_id
    GROUP BY 
        a.id, a.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    md.cast_count,
    pd.actor_id,
    pd.name AS actor_name,
    pd.info AS actor_info
FROM 
    movie_details md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    person_details pd ON ci.person_id = pd.actor_id
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, md.title;
