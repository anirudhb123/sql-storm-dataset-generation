WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_titles AS (
    SELECT 
        title_id,
        title,
        production_year,
        company_count,
        keyword_count
    FROM 
        ranked_titles
    WHERE 
        rank <= 5
),
actor_roles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
title_actor_roles AS (
    SELECT 
        tt.title,
        tt.production_year,
        ar.role,
        ar.actor_count,
        tt.company_count,
        tt.keyword_count
    FROM 
        top_titles tt
    LEFT JOIN 
        actor_roles ar ON tt.title_id = ar.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(t.actor_count, 0) AS actor_count,
    t.company_count,
    t.keyword_count
FROM 
    title_actor_roles t
ORDER BY 
    t.production_year, t.keyword_count DESC;
