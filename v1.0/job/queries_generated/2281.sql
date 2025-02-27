WITH MovieStats AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        AVG(CASE WHEN pi.info_type_id = 1 THEN LENGTH(pi.info) ELSE NULL END) AS avg_person_info_length,
        MAX(CASE WHEN pi.info_type_id = 2 THEN pi.info ELSE NULL END) AS max_person_bio
    FROM 
        aka_title at
    LEFT JOIN 
        movie_info mi ON at.movie_id = mi.movie_id
    LEFT JOIN 
        cast_info ca ON at.movie_id = ca.movie_id
    LEFT JOIN 
        person_info pi ON ca.person_id = pi.person_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.avg_person_info_length,
    ms.max_person_bio,
    ks.keywords_list
FROM 
    MovieStats ms
LEFT JOIN 
    KeywordStats ks ON ms.title = (SELECT at.title FROM aka_title at WHERE at.movie_id = ks.movie_id)
WHERE 
    ms.cast_count > 0
ORDER BY 
    ms.production_year DESC, ms.cast_count DESC
LIMIT 10;

SELECT 
    DISTINCT at.title, 
    ci.note, 
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY at.movie_id) AS num_roles 
FROM 
    aka_title at
FULL OUTER JOIN 
    cast_info ci ON at.movie_id = ci.movie_id
WHERE 
    at.production_year >= 1990 
    AND (ci.note IS NULL OR ci.note NOT LIKE '%uncredited%')
ORDER BY 
    num_roles DESC, at.title
LIMIT 50;

UNION ALL

SELECT 
    at.title,
    cm.name AS company_name, 
    mt.kind AS company_type
FROM 
    aka_title at
INNER JOIN 
    movie_companies mc ON at.movie_id = mc.movie_id
JOIN 
    company_name cm ON mc.company_id = cm.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
WHERE 
    cm.country_code IS NOT NULL
    AND cm.country_code != ''
ORDER BY 
    at.title, company_name;
