WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        a.person_id
),
FilteredActors AS (
    SELECT 
        a.id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCount amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > 5
)
SELECT 
    f.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    COALESCE(mk.keyword, 'No Keyword') AS keyword,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE mc.company_type_id = 1) AS production_companies_count
FROM 
    RankedTitles rt
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON rt.title_id = mc.movie_id
JOIN 
    FilteredActors f ON f.id = rt.title_id
GROUP BY 
    f.name, rt.title, rt.production_year, mk.keyword
ORDER BY 
    rt.production_year DESC, production_companies_count DESC;
