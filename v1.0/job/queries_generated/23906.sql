WITH RECURSIVE TitleHierarchy AS (
    -- Generate a recursive common table expression to find all titles and their associated episodes
    SELECT 
        t.id AS title_id,
        t.title,
        t.season_nr,
        t.episode_nr,
        1 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL  -- Start from the base titles

    UNION ALL

    SELECT 
        e.id AS title_id,
        e.title,
        e.season_nr,
        e.episode_nr,
        th.level + 1
    FROM title e
    JOIN TitleHierarchy th ON e.episode_of_id = th.title_id  -- Recursively find episodes of the titles
)

SELECT 
    ak.name AS actor_name,
    ti.title AS movie_title,
    th.title AS episode_title,
    th.level AS episode_level,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(CASE WHEN m.production_year IS NULL THEN NULL ELSE m.production_year END) AS average_production_year,
    STRING_AGG(DISTINCT ni.info, ', ') AS additional_info
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title ti ON ci.movie_id = ti.movie_id
LEFT JOIN TitleHierarchy th ON ti.id = th.title_id
LEFT JOIN movie_keyword mk ON ti.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_info mi ON ti.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
LEFT JOIN movie_info_idx m ON ti.id = m.movie_id
LEFT JOIN title tm ON ti.id = tm.id
LEFT JOIN title t ON th.title_id = t.id
LEFT JOIN movie_companies mc ON ti.id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id AND cn.country_code IS NULL  -- Edge case for NULL country code

WHERE 
    ak.name IS NOT NULL
    AND th.level BETWEEN 0 AND 5 -- Consider only episodes up to 5 levels deep
    AND (m.production_year IS NOT NULL OR mi.info IS NULL)
GROUP BY 
    ak.name, ti.title, th.title, th.level
HAVING 
    COUNT(DISTINCT k.keyword) > 0  -- Only include actors with associated keywords
ORDER BY 
    ak.name, ti.title;
