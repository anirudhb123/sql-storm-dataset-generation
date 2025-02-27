WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
PopularKeywords AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
    HAVING 
        COUNT(mk.keyword_id) > 3
),
ActorRoles AS (
    SELECT 
        c.movie_id, 
        rt.role, 
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id, rt.role
    HAVING 
        COUNT(c.id) > 1
)
SELECT 
    rt.title, 
    rt.production_year, 
    COALESCE(pkw.keyword_count, 0) AS popular_keyword_count,
    COALESCE(ar.role_count, 0) AS actor_role_count
FROM 
    RankedTitles rt
LEFT JOIN 
    PopularKeywords pkw ON rt.title_id = pkw.movie_id
LEFT JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
