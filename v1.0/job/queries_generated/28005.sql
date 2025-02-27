WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.id) AS keyword_count,
        ARRAY_AGG(DISTINCT mk.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
TitleWithRoles AS (
    SELECT 
        rt.title_id, 
        rt.title, 
        rt.production_year, 
        pr.actor_name, 
        pr.role_name
    FROM 
        RankedTitles rt
    LEFT JOIN 
        PersonRoles pr ON rt.title_id = pr.movie_id
),
TitleKeywordSummary AS (
    SELECT
        title_id,
        title,
        production_year,
        STRING_AGG(actor_name || ' (' || role_name || ')', ', ') AS cast_summary,
        keyword_count,
        keywords
    FROM 
        TitleWithRoles
    GROUP BY 
        title_id, title, production_year, keyword_count, keywords
)
SELECT 
    title_id,
    title,
    production_year,
    cast_summary,
    keyword_count,
    keywords
FROM 
    TitleKeywordSummary
ORDER BY 
    production_year DESC, 
    title;
