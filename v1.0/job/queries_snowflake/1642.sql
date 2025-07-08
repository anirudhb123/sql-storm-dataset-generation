
WITH title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        AVG(CASE WHEN ti.info IS NOT NULL THEN LENGTH(ti.info) ELSE 0 END) AS avg_info_length
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info ti ON t.id = ti.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
), 
movie_keyword_summary AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    ti.title,
    ti.production_year,
    ai.name AS lead_actor,
    ai.total_movies,
    ti.total_companies,
    ti.avg_info_length,
    mks.keywords
FROM 
    title_info ti
JOIN 
    complete_cast cc ON ti.title_id = cc.movie_id
JOIN 
    actor_info ai ON cc.subject_id = ai.actor_id
LEFT JOIN 
    movie_keyword_summary mks ON ti.title_id = mks.movie_id
WHERE 
    ai.movie_rank <= 10
ORDER BY 
    ti.production_year DESC, 
    ti.total_companies DESC, 
    ai.total_movies DESC;
