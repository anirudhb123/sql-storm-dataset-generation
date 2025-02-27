WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_counts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
company_movies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title,
    rt.production_year,
    ac.actor_count,
    cm.company_name,
    cm.company_type,
    CASE 
        WHEN ac.actor_count IS NULL THEN 'No Actors'
        ELSE CONCAT('Total Actors: ', ac.actor_count)
    END AS actor_info,
    STRING_AGG(k.keyword, ', ') AS keywords
FROM 
    ranked_titles rt
LEFT JOIN 
    actor_counts ac ON rt.title_id = ac.movie_id
LEFT JOIN 
    company_movies cm ON rt.title_id = cm.movie_id
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    rt.rn <= 5 OR cm.company_type IS NULL
GROUP BY 
    rt.title, rt.production_year, ac.actor_count, cm.company_name, cm.company_type
ORDER BY 
    rt.production_year DESC, rt.title;
