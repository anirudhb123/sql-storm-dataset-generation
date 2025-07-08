
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

movie_casts AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),

comp_movies AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title AS movie_title,
    rt.production_year,
    mc.cast_count,
    mc.actor_names,
    co.company_count,
    co.company_names,
    rt.keyword_count
FROM 
    ranked_titles rt
JOIN 
    movie_casts mc ON rt.title_id = mc.movie_id
JOIN 
    comp_movies co ON rt.title_id = co.movie_id
WHERE 
    rt.rank = 1
ORDER BY 
    rt.production_year DESC, 
    rt.keyword_count DESC;
