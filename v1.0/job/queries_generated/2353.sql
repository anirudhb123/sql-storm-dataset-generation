WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(cc.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.id, k.keyword
), 
company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
), 
actor_info AS (
    SELECT 
        p.id AS person_id,
        p.name,
        COUNT(ci.movie_id) AS movies_count,
        ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY COUNT(ci.movie_id) DESC) AS rn
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    GROUP BY 
        p.id, p.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    ci.company_name,
    ci.company_type,
    ai.name AS actor_name,
    ai.movies_count
FROM 
    movie_details md
FULL OUTER JOIN 
    company_info ci ON md.movie_id = ci.movie_id
FULL OUTER JOIN 
    actor_info ai ON md.movie_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = ai.person_id)
WHERE 
    md.production_year IS NOT NULL OR ci.company_name IS NOT NULL
    AND (md.cast_count > 1 OR ai.movies_count > 5)
ORDER BY 
    md.production_year DESC NULLS LAST, 
    md.title ASC, 
    ai.movies_count DESC;
