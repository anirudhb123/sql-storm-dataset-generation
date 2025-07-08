WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_year
    FROM 
        title t
),
movie_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, k.keyword
),
combined_actors AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        c.movie_id,
        c.role_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.id) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        name a ON ak.person_id = a.id
)
SELECT 
    rt.title,
    rt.production_year,
    COUNT(DISTINCT ka.actor_name) AS total_actors,
    MAX(mk.keyword_count) AS max_keywords
FROM 
    ranked_titles rt
LEFT JOIN 
    movie_with_keywords mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    combined_actors ka ON mk.movie_id = ka.movie_id
WHERE 
    rt.rank_year <= 10
GROUP BY 
    rt.title, rt.production_year
ORDER BY 
    rt.production_year DESC, total_actors DESC;
