WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
), 
FilteredCast AS (
    SELECT 
        ci.movie_id,
        c.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
), 
TitleStatistics AS (
    SELECT 
        rt.title_id,
        COUNT(DISTINCT fc.actor_name) AS actor_count,
        STRING_AGG(DISTINCT fc.actor_name, ', ') AS actor_list,
        STRING_AGG(DISTINCT rt.keyword, ', ') AS keywords_collected
    FROM 
        RankedTitles rt
    LEFT JOIN 
        FilteredCast fc ON rt.title_id = fc.movie_id
    GROUP BY 
        rt.title_id
)
SELECT 
    t.title,
    ts.actor_count,
    ts.actor_list,
    ts.keywords_collected,
    t.production_year
FROM 
    title t
JOIN 
    TitleStatistics ts ON t.id = ts.title_id
WHERE 
    ts.actor_count > 5
ORDER BY 
    t.production_year DESC, ts.actor_count DESC;
