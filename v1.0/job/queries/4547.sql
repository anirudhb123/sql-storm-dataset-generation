WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
movie_cast AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ct.kind AS role_type,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        comp_cast_type ct ON ct.id = c.person_role_id
),
movie_info_ext AS (
    SELECT 
        m.movie_id,
        MIN(m.info) AS first_info,
        MAX(m.info) AS last_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_info m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.title,
    r.production_year,
    mc.actor_name,
    mc.role_type,
    mie.first_info,
    mie.last_info,
    mie.keyword_count,
    COALESCE(mie.keyword_count, 0) AS adjusted_keyword_count 
FROM 
    ranked_titles r
LEFT JOIN 
    movie_cast mc ON mc.movie_id = (SELECT id FROM title t WHERE t.title = r.title AND t.production_year = r.production_year LIMIT 1)
LEFT JOIN 
    movie_info_ext mie ON mie.movie_id = (SELECT id FROM title t WHERE t.title = r.title AND t.production_year = r.production_year LIMIT 1)
WHERE 
    r.title_rank <= 5
ORDER BY 
    r.production_year DESC, 
    r.title ASC;
