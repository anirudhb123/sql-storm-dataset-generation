
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        NULL AS parent_id, 
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL
    
    SELECT 
        e.id AS movie_id, 
        e.title, 
        e.production_year, 
        e.episode_of_id AS parent_id, 
        h.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy h ON e.episode_of_id = h.movie_id
),

FormattedTitles AS (
    SELECT 
        movie_id,
        title,
        production_year,
        level,
        REPLACE(REPLACE(title, ' ', '_'), '''', '') AS clean_title
    FROM 
        MovieHierarchy
),

MovieKeywords AS (
    SELECT 
        k.movie_id,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        movie_keyword k
    JOIN 
        keyword kw ON k.keyword_id = kw.id
    GROUP BY 
        k.movie_id
),

MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    ft.movie_id,
    ft.clean_title,
    ft.production_year,
    ft.level,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mc.companies, 'No companies') AS companies
FROM 
    FormattedTitles ft
LEFT JOIN 
    MovieKeywords mk ON ft.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON ft.movie_id = mc.movie_id
WHERE 
    ft.production_year >= 2000
ORDER BY 
    ft.level, ft.production_year DESC;
