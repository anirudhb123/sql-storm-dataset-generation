WITH RECURSIVE TitleHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        t.episode_of_id,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        t.episode_of_id,
        th.level + 1
    FROM 
        aka_title t
    JOIN 
        TitleHierarchy th ON th.title_id = t.episode_of_id
)
SELECT 
    t.title AS main_title, 
    COUNT(DISTINCT c.id) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    STRING_AGG(DISTINCT m.name, ', ') AS companies,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length,
    CASE 
        WHEN MIN(tc.kind_id) IS NULL THEN 'No Type' 
        ELSE MAX(tc.kind_id) 
    END AS title_kind,
    MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No Note' END) AS latest_cast_note
FROM 
    TitleHierarchy th 
JOIN 
    aka_title t ON th.title_id = t.id
LEFT JOIN 
    cast_info c ON t.id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    kind_type tc ON t.kind_id = tc.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
GROUP BY 
    t.title, th.level
HAVING 
    COUNT(DISTINCT c.id) > 5 AND
    MAX(tc.kind_id) IS NOT NULL
ORDER BY 
    avg_info_length DESC NULLS LAST
LIMIT 50;

WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS row_num
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
)
SELECT 
    COUNT(*) AS movie_count,
    MAX(row_num) AS max_row_num
FROM 
    RankedMovies
WHERE 
    movie_id IN (
        SELECT DISTINCT movie_id 
        FROM movie_info 
        WHERE info LIKE '%Award%'
    )
AND row_num > 10
ORDER BY 
    movie_count DESC;
