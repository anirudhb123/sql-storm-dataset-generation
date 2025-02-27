WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),

unique_co_producers AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Co-Producer')
    GROUP BY 
        mc.movie_id, c.name
),

actor_movie_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)

SELECT 
    rt.title_id, 
    rt.title, 
    rt.production_year, 
    MAX(uc.company_count) AS unique_company_count, 
    MAX(ac.actor_count) AS actor_count
FROM 
    ranked_titles rt
LEFT JOIN 
    unique_co_producers uc ON rt.title_id = uc.movie_id
LEFT JOIN 
    actor_movie_counts ac ON rt.title_id = ac.movie_id
WHERE 
    rt.year_rank <= 5
GROUP BY 
    rt.title_id, rt.title, rt.production_year
ORDER BY 
    rt.production_year DESC, unique_company_count DESC, actor_count DESC;
