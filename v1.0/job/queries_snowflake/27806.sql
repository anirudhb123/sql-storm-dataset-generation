WITH ranked_titles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        k.keyword, 
        ROW_NUMBER() OVER (PARTITION BY k.keyword ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
top_cast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.title AS title,
        rt.production_year,
        ROW_NUMBER() OVER (PARTITION BY rt.title ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        ranked_titles rt ON ci.movie_id = rt.title_id
    WHERE 
        rt.rn = 1
),
movie_summary AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT cc.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        ranked_titles t
    LEFT JOIN 
        movie_companies cc ON t.title_id = cc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.rn = 1
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    m.title,
    m.production_year,
    m.company_count,
    m.keyword_count,
    tc.actor_name,
    tc.actor_rank
FROM 
    movie_summary m
JOIN 
    top_cast tc ON m.title = tc.title AND m.production_year = tc.production_year
ORDER BY 
    m.production_year DESC, 
    m.title ASC, 
    tc.actor_rank;
