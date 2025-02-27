
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_notes
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
directors AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(d.name, ', ' ORDER BY d.name) AS director_names
    FROM 
        movie_companies mc
    JOIN 
        company_name d ON mc.company_id = d.id 
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    GROUP BY 
        mc.movie_id
),
movies_with_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.avg_cast_notes,
    COALESCE(d.director_names, 'Unknown') AS director_names,
    COALESCE(mkw.keywords, 'No keywords') AS keywords
FROM 
    movie_details md
LEFT JOIN 
    directors d ON md.movie_id = d.movie_id
LEFT JOIN 
    movies_with_keywords mkw ON md.movie_id = mkw.movie_id
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
