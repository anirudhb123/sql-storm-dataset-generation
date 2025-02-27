WITH movie_rankings AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL AND
        t.title IS NOT NULL
    GROUP BY 
        t.id
),
keyword_rankings AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
movie_details AS (
    SELECT 
        mr.movie_title,
        mr.production_year,
        mr.cast_count,
        mr.cast_names,
        kr.keywords
    FROM 
        movie_rankings mr
    LEFT JOIN 
        keyword_rankings kr ON mr.movie_title = kr.movie_id
    ORDER BY 
        mr.production_year DESC,
        mr.cast_count DESC
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    md.keywords
FROM 
    movie_details md
WHERE 
    md.cast_count > 5
ORDER BY 
    md.production_year DESC;
