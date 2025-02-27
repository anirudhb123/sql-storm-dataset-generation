WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TitleWithKeywords AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedTitles rt
    JOIN 
        movie_keyword mk ON rt.title_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rt.title_id, rt.title, rt.production_year
),
CastInfoFiltered AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        p.name AS actor_name,
        rt.title,
        rt.production_year,
        ci.role_id
    FROM 
        cast_info ci
    JOIN 
        person_info pi ON ci.person_id = pi.person_id
    JOIN 
        name p ON pi.person_id = p.id
    JOIN 
        TitleWithKeywords rt ON ci.movie_id = rt.title_id
    WHERE 
        pi.info LIKE '%actor%'
        AND p.name IS NOT NULL
)
SELECT 
    C.movie_id,
    C.actor_name,
    COUNT(DISTINCT C.role_id) AS unique_roles,
    T.keywords
FROM 
    CastInfoFiltered C
JOIN 
    TitleWithKeywords T ON C.title = T.title
GROUP BY 
    C.movie_id, C.actor_name, T.keywords
HAVING 
    COUNT(DISTINCT C.role_id) > 1
ORDER BY 
    C.movie_id, C.actor_name;
