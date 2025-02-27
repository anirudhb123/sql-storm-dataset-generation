WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(NULLIF(t.season_nr, 0), 'N/A') AS season,
        COALESCE(NULLIF(t.episode_nr, 0), 'N/A') AS episode,
        t.kind_id,
        t.imdb_index,
        t.phonetic_code,
        t.episode_of_id
    FROM 
        aka_title t
    WHERE 
        t.production_year = (SELECT MAX(production_year) FROM aka_title)
    
    UNION ALL
    
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(NULLIF(t.season_nr, 0), 'N/A') AS season,
        COALESCE(NULLIF(t.episode_nr, 0), 'N/A') AS episode,
        t.kind_id,
        t.imdb_index,
        t.phonetic_code,
        t.episode_of_id
    FROM 
        aka_title t
    INNER JOIN 
        title_hierarchy th ON th.episode_of_id = t.id
)
SELECT 
    t.title_id,
    t.title,
    t.production_year,
    COALESCE(cast_info.nr_order, 0) AS order_num,
    CASE 
        WHEN CAST(t.production_year AS INTEGER) >= 2000 THEN 'Modern Era'
        WHEN CAST(t.production_year AS INTEGER) < 2000 AND CAST(t.production_year AS INTEGER) >= 1980 THEN 'Millennium Era'
        ELSE 'Classic Era'
    END AS era,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    COUNT(DISTINCT ci.person_role_id) FILTER (WHERE ci.note IS NOT NULL) AS cast_with_notes
FROM 
    title_hierarchy t
LEFT JOIN 
    movie_keyword mk ON t.title_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON t.title_id = ci.movie_id
WHERE 
    t.production_year IS NOT NULL 
    AND (t.episode_of_id IS NULL OR EXISTS(SELECT 1 FROM title x WHERE x.id = t.episode_of_id))
GROUP BY 
    t.title_id, t.title, t.production_year, order_num, era
ORDER BY 
    t.production_year DESC, keyword_count DESC;
