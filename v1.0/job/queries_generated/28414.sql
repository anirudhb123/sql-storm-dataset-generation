WITH actor_titles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ARRAY_AGG(DISTINCT t.title) AS titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON c.person_id = a.person_id
    JOIN 
        aka_title t ON t.id = c.movie_id
    GROUP BY 
        a.id, a.name
),
title_keywords AS (
    SELECT 
        t.id AS title_id,
        t.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        t.id, t.title
),
actor_details AS (
    SELECT 
        at.actor_id,
        at.actor_name,
        ARRAY_LENGTH(at.titles, 1) AS title_count,
        COALESCE(tk.keywords, ARRAY[]::text[]) AS keywords
    FROM 
        actor_titles at
    LEFT JOIN 
        title_keywords tk ON tk.title = ANY(at.titles)
)
SELECT 
    ad.actor_id,
    ad.actor_name,
    ad.title_count,
    unnest(ad.keywords) AS keyword
FROM 
    actor_details ad
WHERE 
    ad.title_count > 5
ORDER BY 
    ad.actor_name,
    keyword;
