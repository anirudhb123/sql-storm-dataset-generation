WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    WHERE 
        t.production_year IS NOT NULL
)

SELECT 
    rt.title,
    rt.production_year,
    rt.cast_count,
    COALESCE(an.name, 'Unknown') AS leading_role,
    COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS role_filled_count,
    STRING_AGG(DISTINCT ci.note, ', ') AS notes
FROM 
    RankedTitles AS rt
LEFT JOIN 
    cast_info AS ci ON rt.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
LEFT JOIN 
    aka_name AS an ON ci.person_id = an.person_id
GROUP BY 
    rt.title, rt.production_year, an.name
HAVING 
    rt.cast_count > 2
ORDER BY 
    rt.production_year DESC, 
    rt.cast_count DESC 
LIMIT 10;

WITH MovieStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(mk.keyword_id) AS avg_keyword_id
    FROM 
        movie_companies AS mc
    JOIN 
        movie_keyword AS mk ON mc.movie_id = mk.movie_id
    GROUP BY 
        mc.movie_id
)

SELECT 
    t.title,
    t.production_year,
    ms.company_count,
    ms.avg_keyword_id,
    CASE 
        WHEN ms.company_count > 5 THEN 'High'
        WHEN ms.company_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS company_rating,
    (SELECT COUNT(*) FROM movie_info WHERE movie_id = t.id) AS info_count
FROM 
    aka_title AS t
JOIN 
    MovieStats AS ms ON t.id = ms.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    company_rating, info_count DESC;
