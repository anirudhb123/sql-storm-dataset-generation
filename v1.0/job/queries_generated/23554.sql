WITH ranked_titles AS (
    SELECT 
        a.person_id,
        a.name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY a.person_id) AS total_titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),

top_titles AS (
    SELECT 
        person_id,
        name,
        title,
        production_year,
        total_titles
    FROM 
        ranked_titles
    WHERE 
        rn = 1
),

coalesced_titles AS (
    SELECT 
        t.*, 
        COALESCE(NULLIF(t.title, ''), 'Unknown Title') AS safe_title 
    FROM 
        top_titles t
),

movies_with_keywords AS (
    SELECT 
        COALESCE(mk.movie_id, -1) AS movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    c.name AS actor_name,
    ct.title AS movie_title,
    ct.production_year,
    COALESCE(mw.keywords, 'No Keywords') AS keywords,
    NULLIF(tmp.total_titles, 0) AS total_titles
FROM 
    coalesced_titles ct
JOIN 
    aka_name c ON ct.person_id = c.person_id
LEFT JOIN 
    movies_with_keywords mw ON ct.title = mw.movie_id
LEFT JOIN 
    complete_cast tmp ON ct.title = tmp.subject_id
WHERE 
    CASE 
        WHEN ct.production_year < 2000 THEN ct.production_year < 1990
        ELSE ct.production_year BETWEEN 2000 AND 2020
    END 
AND 
    (ct.title IS NOT NULL OR ct.title <> '')
ORDER BY 
    total_titles DESC NULLS LAST, 
    ct.production_year DESC;

