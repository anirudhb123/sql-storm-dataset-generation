WITH recursive title_hierarchy AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        COALESCE(et.season_nr, 0) AS season,
        COALESCE(et.episode_nr, 0) AS episode,
        1 AS depth
    FROM title t
    LEFT JOIN aka_title at ON t.id = at.movie_id
    LEFT JOIN title et ON at.episode_of_id = et.id
    WHERE et.id IS NULL
    
    UNION ALL
    
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        COALESCE(et.season_nr, 0) AS season,
        COALESCE(et.episode_nr, 0) AS episode,
        depth + 1
    FROM title t
    INNER JOIN aka_title at ON t.id = at.movie_id
    INNER JOIN title_hierarchy th ON at.episode_of_id = th.title_id
)
, company_info AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) OVER (PARTITION BY mc.movie_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS rn
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    th.title_id,
    th.title,
    th.production_year,
    th.season,
    th.episode,
    ci.company_name,
    ci.company_type,
    COALESCE(EXTRACT(YEAR FROM CURRENT_DATE) - th.production_year, 9999) AS years_since_release,
    SUM(CASE WHEN ci.company_count > 1 THEN 1 ELSE 0 END) OVER (PARTITION BY th.title_id) AS multi_company_indicator,
    CASE WHEN ci.company_name IS NULL THEN 'No Company Info' ELSE ci.company_name END AS company_info_display,
    (SELECT COUNT(*)
     FROM movie_info mi
     WHERE mi.movie_id = th.title_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_info_count
FROM title_hierarchy th
LEFT JOIN company_info ci ON th.title_id = ci.movie_id
ORDER BY th.production_year DESC, th.title;
