WITH RECURSIVE film_series AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        NULL AS parent_id,
        CAST(1 AS INTEGER) AS level
    FROM title t
    WHERE t.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        fs.title_id AS parent_id,
        fs.level + 1
    FROM title t
    JOIN film_series fs ON t.episode_of_id = fs.title_id
),
actor_movie AS (
    SELECT 
        ka.id AS actor_id,
        ka.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    GROUP BY ka.id, ka.name
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT m.name, ', ') AS company_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM movie_info mi
    JOIN movie_companies mc ON mi.movie_id = mc.movie_id
    JOIN company_name m ON mc.company_id = m.id
    LEFT JOIN movie_keyword mk ON mi.movie_id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mi.movie_id
)
SELECT 
    fs.title AS series_title,
    fs.production_year AS series_year,
    fs.level AS series_level,
    am.actor_name,
    am.movie_count,
    md.company_names,
    md.keywords,
    COALESCE(md.info_count, 0) AS info_count,
    CASE 
        WHEN mf.movie_id IS NOT NULL THEN 'Exists in Movie Info'
        ELSE 'Does Not Exist'
    END AS movie_info_status
FROM film_series fs
LEFT JOIN actor_movie am ON am.movie_count > 0
LEFT JOIN movie_info_details md ON md.movie_id = fs.title_id
LEFT JOIN movie_info mf ON fs.title_id = mf.movie_id AND mf.info IS NOT NULL
WHERE fs.production_year BETWEEN 2000 AND 2023
AND am.actor_id IN (
    SELECT id FROM aka_name WHERE md5sum IS NOT NULL OR name_pcode_nf IS NULL
)
ORDER BY fs.series_level DESC, am.movie_count DESC, fs.production_year ASC
LIMIT 50 OFFSET 0;
