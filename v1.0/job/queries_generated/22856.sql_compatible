
WITH RECURSIVE cast_hierarchy AS (
    SELECT 
        ci.person_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY ci.nr_order) AS rn
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL 
        AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
filtered_cast AS (
    SELECT 
        ch.person_id,
        ch.movie_title,
        ch.production_year,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM person_info pi 
                WHERE pi.person_id = ch.person_id 
                AND pi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%famous%')
            ) THEN 'Famous Actor'
            ELSE 'Regular Actor'
        END AS actor_type
    FROM 
        cast_hierarchy ch
    WHERE 
        ch.movie_title ILIKE '%adventure%'
        AND ch.rn <= 5
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        m.id, m.title
)
SELECT 
    fc.movie_title,
    fc.production_year,
    fc.actor_type,
    COALESCE(md.companies, 'No Companies') AS production_companies,
    COUNT(*) OVER (PARTITION BY fc.movie_title) AS total_cast_members,
    STRING_AGG(DISTINCT pi.info, '; ') FILTER (WHERE pi.info IS NOT NULL) AS additional_info
FROM 
    filtered_cast fc
LEFT JOIN 
    movie_details md ON fc.movie_title = md.movie_title
LEFT JOIN 
    person_info pi ON pi.person_id = fc.person_id
WHERE 
    (fc.production_year = (SELECT MAX(production_year) FROM filtered_cast) OR fc.production_year IS NULL)
GROUP BY 
    fc.movie_title, 
    fc.production_year, 
    fc.actor_type, 
    md.companies
ORDER BY 
    fc.production_year DESC, fc.movie_title;
