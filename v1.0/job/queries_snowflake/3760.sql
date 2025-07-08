
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
actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
), 
movie_keywords AS (
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
    rt.title,
    rt.production_year,
    ad.name AS actor_name,
    ad.movie_count,
    mk.keywords,
    COALESCE(mk.keywords, 'No Keywords') AS keyword_info
FROM 
    ranked_titles rt
LEFT JOIN 
    complete_cast cc ON rt.title_id = cc.movie_id
LEFT JOIN 
    actor_details ad ON cc.subject_id = ad.actor_id
LEFT JOIN 
    movie_keywords mk ON rt.title_id = mk.movie_id
WHERE 
    rt.rn <= 5 
AND 
    rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, rt.title;
