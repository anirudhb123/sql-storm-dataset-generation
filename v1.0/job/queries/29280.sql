WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    WHERE 
        t.production_year > 2000
        AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
),

TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON k.id = mt.keyword_id
    GROUP BY 
        mt.movie_id
),

CompletedCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.subject_id) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        complete_cast cc
    JOIN 
        aka_name a ON a.person_id = cc.subject_id
    GROUP BY 
        cc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    rt.actor_name,
    rt.actor_rank,
    tk.keywords,
    cc.total_cast_members,
    cc.cast_names
FROM 
    RankedTitles rt
LEFT JOIN 
    TitleKeywords tk ON tk.movie_id = rt.title_id
LEFT JOIN 
    CompletedCast cc ON cc.movie_id = rt.title_id
ORDER BY 
    rt.production_year DESC, rt.title;
