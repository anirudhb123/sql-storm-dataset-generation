WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.season_nr,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id IS NOT NULL

    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.season_nr,
        th.level + 1
    FROM 
        aka_title t
    JOIN 
        title_hierarchy th ON t.episode_of_id = th.title_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT tt.title_id) AS total_titles,
    MAX(tt.production_year) AS latest_production_year,
    STRING_AGG(DISTINCT tt.title, ', ') AS titles,
    SUM(CASE 
            WHEN tt.season_nr IS NOT NULL THEN 1 
            ELSE 0 
        END) AS total_seasons,
    NULLIF(SUM(CASE WHEN tt.season_nr IS NULL THEN 1 ELSE 0 END), 0) AS total_movies_without_seasons
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title_hierarchy tt ON ci.movie_id = tt.title_id
LEFT JOIN 
    movie_info mi ON tt.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Duration')
LEFT JOIN 
    (SELECT 
        movie_id, 
        COUNT(DISTINCT company_id) AS total_companies 
     FROM 
        movie_companies 
     GROUP BY movie_id) mc ON mc.movie_id = tt.title_id
WHERE 
    a.name IS NOT NULL AND 
    (a.md5sum IS NOT NULL OR a.surname_pcode IS NOT NULL)
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT tt.title_id) > 1
ORDER BY 
    total_titles DESC, latest_production_year DESC
LIMIT 10;

-- Performing additional analysis
SELECT 
    actor_name,
    total_titles,
    latest_production_year,
    titles,
    total_seasons,
    total_movies_without_seasons
FROM (
    -- Inline view for later analysis
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT tt.title_id) AS total_titles,
        MAX(tt.production_year) AS latest_production_year,
        STRING_AGG(DISTINCT tt.title, ', ') AS titles,
        SUM(CASE 
                WHEN tt.season_nr IS NOT NULL THEN 1 
                ELSE 0 
            END) AS total_seasons,
        NULLIF(SUM(CASE WHEN tt.season_nr IS NULL THEN 1 ELSE 0 END), 0) AS total_movies_without_seasons
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title_hierarchy tt ON ci.movie_id = tt.title_id
    LEFT JOIN 
        movie_info mi ON tt.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Duration')
    LEFT JOIN 
        (SELECT 
            movie_id, 
            COUNT(DISTINCT company_id) AS total_companies 
         FROM 
            movie_companies 
         GROUP BY movie_id) mc ON mc.movie_id = tt.title_id
    WHERE 
        a.name IS NOT NULL AND 
        (a.md5sum IS NOT NULL OR a.surname_pcode IS NOT NULL)
    GROUP BY 
        a.id
    HAVING 
        COUNT(DISTINCT tt.title_id) > 1
) AS actor_summary
WHERE 
    total_seasons > total_movies_without_seasons
ORDER BY 
    total_titles DESC;

-- Union with company analysis section
SELECT 
    cn.name AS company_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS involved_titles
FROM 
    company_name cn
JOIN 
    movie_companies mc ON cn.id = mc.company_id
JOIN 
    aka_title t ON mc.movie_id = t.id
WHERE 
    cn.country_code IS NOT NULL 
GROUP BY 
    cn.id
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 5;
