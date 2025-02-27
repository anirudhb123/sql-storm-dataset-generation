WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        th.level + 1
    FROM 
        aka_title t
    JOIN 
        title_hierarchy th ON t.episode_of_id = th.title_id
)
SELECT 
    th.title,
    th.production_year,
    th.level,
    COUNT(c.movie_id) AS actor_count,
    AVG(CASE 
        WHEN ci.nr_order IS NULL THEN NULL
        ELSE ci.nr_order
    END) AS avg_order,
    STRING_AGG(DISTINCT ak.name || ' (' || COALESCE(NULLIF(ak.md5sum, ''), 'No MD5') || ')', ', ') AS actors
FROM 
    title_hierarchy th
LEFT JOIN 
    complete_cast cc ON th.title_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON th.title_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    th.production_year > 2000 
    AND th.level <= 2
GROUP BY 
    th.title, th.production_year, th.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    th.production_year DESC,
    th.level ASC,
    actor_count DESC
LIMIT 10;

-- Including a bizarre semantic aspect, assuming there could be a 
-- NULL for production_year check that counts only titles with nulls
WITH interesting_titles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        COALESCE(NULLIF(title.production_year, 0), NULL) AS production_year
    FROM 
        title
    WHERE 
        title.production_year IS NULL OR title.production_year < 2000
)
SELECT 
    t.title,
    mt.note AS movie_note
FROM 
    interesting_titles t
LEFT JOIN 
    movie_info mt ON t.title_id = mt.movie_id
WHERE 
    NOT (mt.info_type_id IS NULL AND t.production_year IS NOT NULL)
ORDER BY 
    t.title;

-- Checking for kind_id in an exotic fashion with CASE logic.
SELECT 
    kt.kind,
    COUNT(m.movie_id) AS movies_count,
    SUM(CASE 
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 1 
        ELSE 0 
    END) AS count_2000s,
    SUM(CASE 
        WHEN m.production_year > 2010 AND m.production_year IS NOT NULL 
        THEN 2 
        ELSE 0 
    END) AS count_after_2010,
    MIN(m.production_year) AS first_movie_year,
    MAX(m.production_year) AS last_movie_year
FROM 
    kind_type kt
JOIN 
    aka_title m ON kt.id = m.kind_id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
WHERE 
    mi.info_type_id IS NOT NULL
    AND (mi.note IS NULL OR mi.note <> '')
GROUP BY 
    kt.kind
HAVING 
    COUNT(m.movie_id) > 10
ORDER BY 
    movies_count DESC;
