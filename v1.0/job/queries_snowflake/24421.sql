
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        COALESCE(c.note, 'No notes') AS cast_note,
        COUNT(*) OVER (PARTITION BY c.person_id) AS movies_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
company_movies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
title_agg AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        am.actor_name,
        am.cast_note,
        cm.company_names,
        cm.company_count,
        ki.keyword,
        ki.keyword_count
    FROM 
        ranked_titles rt
    LEFT JOIN 
        actor_movies am ON rt.title_id = am.movie_id
    LEFT JOIN 
        company_movies cm ON rt.title_id = cm.movie_id
    LEFT JOIN 
        keyword_info ki ON rt.title_id = ki.movie_id
)
SELECT 
    ta.title,
    ta.production_year,
    MAX(ta.actor_name) AS leading_actor,
    SUM(CASE WHEN ta.cast_note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_actor_count,
    COALESCE(SUM(ta.company_count), 0) AS total_companies,
    LISTAGG(DISTINCT ta.keyword, ', ') AS keywords_list,
    COUNT(*) OVER (PARTITION BY ta.production_year) AS total_movies_by_year
FROM 
    title_agg ta
GROUP BY 
    ta.title, ta.production_year
HAVING 
    COUNT(DISTINCT ta.actor_name) > 1
ORDER BY 
    ta.production_year DESC, COUNT(DISTINCT ta.actor_name) DESC
LIMIT 10;
