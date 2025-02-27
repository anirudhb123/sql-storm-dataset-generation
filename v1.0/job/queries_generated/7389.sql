WITH ranked_titles AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
popular_actors AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
keyword_summary AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title, 
    rt.production_year, 
    rt.company_count, 
    pa.actor_name, 
    pa.movie_count, 
    ks.keywords
FROM 
    ranked_titles rt
JOIN 
    popular_actors pa ON rt.rank <= 5 AND rt.production_year = (SELECT MAX(production_year) FROM ranked_titles)
LEFT JOIN 
    keyword_summary ks ON rt.id = ks.movie_id
WHERE 
    rt.company_count > 1
ORDER BY 
    rt.production_year DESC, 
    rt.company_count DESC, 
    pa.movie_count DESC;
