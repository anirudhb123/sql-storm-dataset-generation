WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
),
person_details AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS roles_with_notes
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id
)
SELECT 
    md.movie_id,
    md.title,
    md.keywords,
    md.production_year,
    pd.name AS actor_name,
    pd.movies_count,
    pd.roles_with_notes,
    RANK() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank_by_cast
FROM 
    movie_details md
JOIN 
    person_details pd ON pd.movies_count > 0
WHERE 
    md.production_year >= 2000
    AND MD.keywords NOT LIKE '%Action%'
ORDER BY 
    md.production_year DESC,
    md.cast_count DESC;
