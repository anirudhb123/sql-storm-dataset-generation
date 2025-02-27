WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        p.name AS actor_name,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'Lead Actor')

    UNION ALL

    SELECT 
        ci.person_id,
        CONCAT(p.name, ' (Supporting)') AS actor_name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id LIMIT 1)
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        ci.role_id != (SELECT id FROM role_type WHERE role = 'Lead Actor')
)

SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    MAX(m.production_year) OVER (PARTITION BY a.actor_name) AS last_movie_year
FROM 
    ActorHierarchy a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.actor_name
ORDER BY 
    movie_count DESC, last_movie_year DESC
LIMIT 10;

-- Additionally, calculating the popularity of the top 5 movies excluding any invalid titles
SELECT 
    m.title,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    SUM(mi.info IS NOT NULL) AS total_info_types,
    COALESCE(k.keyword, 'No Keywords') AS keywords
FROM 
    aka_title m
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.title IS NOT NULL AND m.title <> ''
GROUP BY 
    m.title, k.keyword
ORDER BY 
    cast_count DESC
LIMIT 5;

-- Finding all companies that collaborated in movies with the highest production years and their types
SELECT 
    cn.name AS company_name,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(m.production_year) AS average_production_year
FROM 
    movie_companies mc
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    aka_title m ON mc.movie_id = m.id
WHERE 
    m.production_year = (SELECT MAX(production_year) FROM aka_title)
GROUP BY 
    cn.name, ct.kind
ORDER BY 
    movie_count DESC;
