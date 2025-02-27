WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id, 
        a.name AS aka_name, 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER(PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
),
HighlightedActors AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
),
PopularKeywords AS (
    SELECT 
        k.keyword, 
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    HAVING 
        COUNT(mk.movie_id) > 10
)
SELECT 
    h.actor_name, 
    rt.title, 
    rt.production_year, 
    pk.keyword, 
    pk.keyword_count
FROM 
    RankedTitles rt
JOIN 
    HighlightedActors h ON rt.aka_id = h.actor_id
JOIN 
    PopularKeywords pk ON pk.keyword_count > 0
WHERE 
    rt.rn = 1 
ORDER BY 
    h.movie_count DESC, rt.production_year DESC;
