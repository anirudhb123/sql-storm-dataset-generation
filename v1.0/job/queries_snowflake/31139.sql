
WITH RECURSIVE cast_hierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        c.person_id,
        c.nr_order,
        1 AS depth
    FROM 
        cast_info c
    WHERE 
        c.nr_order = 1

    UNION ALL

    SELECT 
        cs.id AS cast_id,
        cs.movie_id,
        cs.person_id,
        cs.nr_order,
        ch.depth + 1
    FROM 
        cast_info cs
    JOIN 
        cast_hierarchy ch ON cs.movie_id = ch.movie_id AND cs.nr_order > ch.nr_order
)
SELECT
    m.title AS movie_title,
    ARRAY_AGG(DISTINCT ak.name) AS actor_names,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    AVG(experience.years_of_experience) AS average_experience_years,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT kw.keyword) AS unique_keywords,
    CASE 
        WHEN AVG(experience.years_of_experience) IS NULL THEN 'No experience data'
        ELSE CAST(AVG(experience.years_of_experience) AS STRING)
    END AS avg_experience,
    COUNT(DISTINCT ci.nr_order) AS distinct_roles
FROM 
    aka_title m
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    (SELECT 
        p.id AS person_id, 
        COUNT(pi.info) AS years_of_experience
     FROM 
        person_info pi
     JOIN 
        aka_name p ON pi.person_id = p.person_id 
     WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Experience')
     GROUP BY p.id) experience ON ci.person_id = experience.person_id
WHERE 
    m.production_year > 2000
GROUP BY 
    m.title, 
    ci.nr_order, 
    ak.name, 
    mc.company_id, 
    kw.keyword, 
    experience.years_of_experience
ORDER BY 
    actor_count DESC, 
    movie_title ASC;
