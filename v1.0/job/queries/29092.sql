WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ci.cast_count,
        ci.cast_names,
        ks.keywords
    FROM 
        ranked_titles rt
    JOIN 
        aka_title m ON rt.title_id = m.id
    LEFT JOIN 
        cast_summary ci ON m.id = ci.movie_id
    LEFT JOIN 
        keyword_summary ks ON m.id = ks.movie_id
)
SELECT 
    mid.movie_id,
    mid.title,
    mid.production_year,
    mid.cast_count,
    mid.cast_names,
    mid.keywords
FROM 
    movie_info_details mid
WHERE 
    mid.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mid.production_year ASC, mid.cast_count DESC;
