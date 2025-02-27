WITH filtered_titles AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        k.keyword AS keyword,
        ARRAY_AGG(DISTINCT c.id) AS cast_ids,
        ARRAY_AGG(DISTINCT a.id) AS aka_ids
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword ILIKE '%action%'
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
person_info_summary AS (
    SELECT 
        p.person_id,
        COUNT(pi.id) AS info_count,
        STRING_AGG(DISTINCT pi.info, ', ') AS info_details
    FROM 
        cast_info ci
    JOIN 
        person_info pi ON ci.person_id = pi.person_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        p.name ILIKE 'J%'
    GROUP BY 
        p.person_id
)
SELECT 
    f.title,
    f.production_year,
    f.keyword,
    f.cast_ids,
    p.info_count,
    p.info_details
FROM 
    filtered_titles f
LEFT JOIN 
    person_info_summary p ON f.cast_ids && ARRAY[p.person_id]
ORDER BY 
    f.production_year DESC, f.title;
