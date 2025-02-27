WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC, t.title) AS title_rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER(ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
)
SELECT 
    rt.title, 
    rt.production_year, 
    rt.company_count, 
    rt.keyword_count, 
    pa.actor_name,
    pa.movie_count
FROM 
    RankedTitles rt
JOIN 
    PopularActors pa ON pa.movie_count > 5
WHERE 
    rt.title_rank <= 3 
ORDER BY 
    rt.production_year DESC, 
    rt.company_count DESC;
