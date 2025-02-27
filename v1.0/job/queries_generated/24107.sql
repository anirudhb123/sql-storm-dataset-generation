WITH movie_years AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        RANK() OVER (PARTITION BY title.production_year ORDER BY title.id) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
actor_stats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MAX(c.nr_order) as max_role_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
top_movies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COALESCE(SUM(mk.movie_id), 0) AS keyword_count,
        COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id 
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.movie_id, m.title, m.production_year, m.kind_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 3
),
combined AS (
    SELECT 
        m.title,
        m.production_year,
        a.name AS actor_name,
        a.surname_pcode,
        a.md5sum AS actor_md5,
        t.kind AS movie_kind,
        ts.year_rank
    FROM 
        top_movies m
    JOIN 
        movie_years ts ON m.production_year = ts.production_year
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        akn_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        kind_type t ON m.kind_id = t.id
)
SELECT 
    c.title,
    c.production_year,
    c.actor_name,
    COUNT(DISTINCT c.year_rank) AS unique_years_ranked,
    AVG((COALESCE(asc.movie_count, 0) + COALESCE(asc.max_role_order, 0))) AS avg_actor_stats
FROM 
    combined c
LEFT JOIN 
    actor_stats asc ON c.actor_name = asc.person_id
WHERE 
    c.surname_pcode IS NOT NULL
GROUP BY 
    c.title, c.production_year, c.actor_name
HAVING 
    avg_actor_stats > 5
ORDER BY 
    c.production_year DESC, unique_years_ranked ASC
LIMIT 10;
