WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_with_actor_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        r.role,
        COALESCE(a.name, 'Unknown') AS actor_name,
        COALESCE(c.note, 'No Role Info') AS role_note
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON c.movie_id = m.id
    LEFT JOIN 
        role_type r ON r.id = c.role_id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        m.production_year > 2000 AND
        m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%')
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
company_movie_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    mwai.title,
    mwai.production_year,
    mwai.actor_name,
    mwai.role,
    mwai.role_note,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    cmp.company_name,
    cmp.company_type,
    cmp.total_movies,
    RANK() OVER (PARTITION BY mwai.production_year ORDER BY mwai.actor_name) AS actor_rank
FROM 
    movie_with_actor_info mwai
LEFT JOIN 
    movie_keywords mk ON mk.movie_id = mwai.movie_id
LEFT JOIN 
    company_movie_info cmp ON cmp.movie_id = mwai.movie_id
WHERE 
    mwai.actor_name IS NOT NULL AND
    (mwai.role_note IS NOT NULL OR mwai.role = 'Lead')
ORDER BY 
    mwai.production_year DESC, actor_rank
LIMIT 50;
