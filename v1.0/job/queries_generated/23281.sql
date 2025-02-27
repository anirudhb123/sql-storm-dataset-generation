WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(ep.season_nr, 0) AS season,
        COALESCE(ep.episode_nr, 0) AS episode,
        1 AS level
    FROM 
        aka_title t
    LEFT JOIN 
        aka_title ep ON t.id = ep.episode_of_id
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ep.id AS title_id,
        ep.title,
        ep.production_year,
        COALESCE(ep2.season_nr, 0) AS season,
        COALESCE(ep2.episode_nr, 0) AS episode,
        level + 1
    FROM 
        aka_title ep
    JOIN 
        title_hierarchy th ON ep.episode_of_id = th.title_id
    LEFT JOIN 
        aka_title ep2 ON ep.id = ep2.episode_of_id
)

SELECT 
    DISTINCT
    th.title,
    th.production_year,
    th.season,
    th.episode,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = th.title_id) AS total_cast,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    SUM(CASE WHEN ts.kind = 'series' THEN 1 ELSE 0 END) AS series_count,
    COUNT(DISTINCT mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL) AS keyword_count,
    ARRAY_AGG(DISTINCT cn.name) AS company_names
FROM 
    title_hierarchy th
LEFT JOIN 
    movie_companies mc ON th.title_id = mc.movie_id
LEFT JOIN 
    kind_type ts ON th.id = ts.id
LEFT JOIN 
    movie_keyword mk ON th.title_id = mk.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    (th.production_year >= 2000 AND th.production_year <= 2023)
    AND th.season = 0
GROUP BY 
    th.title, th.production_year, th.season, th.episode
HAVING 
    COUNT(DISTINCT mc.id) = 
    (SELECT COUNT(*) FROM movie_companies WHERE movie_id = th.title_id)
ORDER BY 
    th.production_year DESC, th.title;
