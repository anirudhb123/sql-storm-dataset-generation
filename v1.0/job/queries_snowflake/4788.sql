
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
CompanyTitles AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    a.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    amc.movie_count,
    ct.company_names
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    RankedTitles rt ON ci.movie_id = rt.title_id
LEFT JOIN 
    ActorMovieCounts amc ON a.person_id = amc.person_id
LEFT JOIN 
    CompanyTitles ct ON ci.movie_id = ct.movie_id
WHERE 
    rt.title_rank <= 5
    AND (amc.movie_count > 3 OR amc.movie_count IS NULL)
GROUP BY 
    a.name, rt.title, rt.production_year, amc.movie_count, ct.company_names
ORDER BY 
    rt.production_year DESC, 
    a.name;
