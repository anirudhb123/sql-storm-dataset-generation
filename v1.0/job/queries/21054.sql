
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_and_titles AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movies_with_keyword AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
title_info AS (
    SELECT 
        ti.movie_id,
        STRING_AGG(DISTINCT ti.info, ', ') AS info_messages
    FROM 
        movie_info ti
    JOIN 
        info_type it ON ti.info_type_id = it.id
    WHERE 
        it.info != 'Pending'
    GROUP BY 
        ti.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(ct.actor_name, 'Unknown Actor') AS actor_name,
    ct.role_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    ti.info_messages
FROM 
    ranked_titles t
LEFT JOIN 
    cast_and_titles ct ON ct.movie_id = t.title_id AND ct.cast_rank = 1
LEFT JOIN 
    movies_with_keyword mk ON mk.movie_id = t.title_id
LEFT JOIN 
    title_info ti ON ti.movie_id = t.title_id
WHERE 
    t.rank <= 10 
    AND (t.production_year >= 2000 OR ct.actor_name IS NULL)
ORDER BY 
    t.production_year DESC, 
    t.title ASC;
