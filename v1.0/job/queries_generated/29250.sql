WITH
recursive_titles AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
cast_details AS (
    SELECT 
        c.movie_id,
        p.id AS person_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order < 5
),
keyword_aggregate AS (
    SELECT 
        title_id,
        STRING_AGG(DISTINCT keyword, ', ') AS all_keywords,
        COUNT(keyword) AS keyword_count
    FROM 
        recursive_titles
    GROUP BY 
        title_id
)
SELECT 
    t.title,
    t.production_year,
    ca.all_keywords,
    ca.keyword_count,
    cd.actor_name,
    cd.role_name
FROM 
    title t
LEFT JOIN 
    keyword_aggregate ca ON t.id = ca.title_id
LEFT JOIN 
    cast_details cd ON t.id = cd.movie_id
WHERE 
    ca.keyword_count >= 3 
ORDER BY 
    t.production_year DESC, 
    ca.keyword_count DESC, 
    t.title;
