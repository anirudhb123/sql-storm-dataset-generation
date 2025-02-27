
WITH movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        STRING_AGG(CONCAT(aka.name, ' (', aka.name_pcode_nf, ')'), ', ') AS aka_names
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name aka ON at.id = aka.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 
cast_details AS (
    SELECT 
        c.movie_id,
        STRING_AGG(CONCAT(p.name, ' as ', r.role), ', ') AS cast_info
    FROM 
        cast_info c
    JOIN 
        person_info pi ON c.person_id = pi.person_id
    JOIN 
        name p ON pi.person_id = p.imdb_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    ti.title_id,
    ti.title,
    ti.production_year,
    ti.kind_id,
    ti.aka_names,
    mk.keywords,
    cd.cast_info
FROM 
    title_info ti
LEFT JOIN 
    movie_keywords mk ON ti.title_id = mk.movie_id
LEFT JOIN 
    cast_details cd ON ti.title_id = cd.movie_id
WHERE 
    ti.production_year >= 2000
ORDER BY 
    ti.production_year DESC, ti.title;
