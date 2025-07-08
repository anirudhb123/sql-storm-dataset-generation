
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
),
ActorCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MAX(c.nr_order) AS highest_order
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        a.person_id
),
LatestMovies AS (
    SELECT 
        m.movie_id, 
        m.title, 
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id DESC) AS latest_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
)
SELECT 
    a.name AS actor_name,
    rt.title AS title,
    rt.production_year,
    ac.movie_count,
    ac.highest_order,
    LISTAGG(DISTINCT kc.keyword, ', ') WITHIN GROUP (ORDER BY kc.keyword) AS keywords,
    COALESCE(ct.kind, 'Unknown') AS company_type
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    RankedTitles rt ON c.movie_id = rt.title_id
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    ActorCounts ac ON a.person_id = ac.person_id
LEFT JOIN 
    LatestMovies lm ON rt.title_id = lm.movie_id AND lm.latest_rank = 1
WHERE 
    rt.title_rank <= 3 
GROUP BY 
    a.name, rt.title, rt.production_year, ac.movie_count, ac.highest_order, ct.kind
HAVING 
    COUNT(DISTINCT kc.id) > 0 OR ct.kind IS NOT NULL
ORDER BY 
    rt.production_year DESC, ac.movie_count DESC;
