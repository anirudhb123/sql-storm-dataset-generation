WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
title_info AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        STRING_AGG(rt.keyword, ', ') AS keywords
    FROM 
        ranked_titles rt
    GROUP BY 
        rt.title_id, rt.title, rt.production_year
),
person_roles AS (
    SELECT 
        c.movie_id,
        p.name AS person_name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
full_cast_info AS (
    SELECT 
        ti.title_id,
        ti.title,
        ti.production_year,
        STRING_AGG(DISTINCT pr.person_name || ' as ' || pr.role, '; ') AS full_cast
    FROM 
        title_info ti
    JOIN 
        person_roles pr ON ti.title_id = pr.movie_id
    GROUP BY 
        ti.title_id, ti.title, ti.production_year
)
SELECT 
    fci.title,
    fci.production_year,
    fci.full_cast,
    COUNT(DISTINCT mk.keyword_id) AS unique_keywords_count
FROM 
    full_cast_info fci
JOIN 
    movie_keyword mk ON fci.title_id = mk.movie_id
GROUP BY 
    fci.title, fci.production_year, fci.full_cast
ORDER BY 
    fci.production_year DESC, unique_keywords_count DESC
LIMIT 10;
