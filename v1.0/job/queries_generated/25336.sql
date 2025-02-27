WITH ranked_titles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND t.title IS NOT NULL
),
count_keywords AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.id
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.actor_name,
    rt.movie_title,
    rt.production_year,
    k.keyword_count,
    ci.company_names,
    ci.company_types
FROM 
    ranked_titles rt
LEFT JOIN 
    count_keywords k ON rt.movie_title = (SELECT title FROM aka_title WHERE id = k.movie_id)
LEFT JOIN 
    company_info ci ON rt.movie_title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
WHERE 
    rt.title_rank = 1  -- Get the latest movie for each actor
ORDER BY 
    rt.actor_name, rt.production_year DESC;
