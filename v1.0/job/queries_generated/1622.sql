WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(ci.movie_id) > 1
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rt.title, 
    rt.production_year, 
    ai.actor_name, 
    mk.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    complete_cast cc ON cc.movie_id IN (SELECT movie_id FROM cast_info ci WHERE ci.nr_order = 1 AND ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Actor'))
JOIN 
    ActorInfo ai ON ai.movie_count > 1
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = cc.movie_id
WHERE 
    rt.title_rank <= 5 AND 
    rt.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
