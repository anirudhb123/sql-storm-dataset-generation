WITH MovieRelease AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS cast_names
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name c ON c.person_id = ci.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
),

KeywordAnalysis AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MovieDetails AS (
    SELECT 
        mr.movie_id,
        mr.movie_title,
        mr.production_year,
        mr.cast_names,
        COALESCE(ka.keyword_count, 0) AS total_keywords
    FROM 
        MovieRelease mr
    LEFT JOIN 
        KeywordAnalysis ka ON mr.movie_id = ka.movie_id
)

SELECT 
    md.movie_title,
    md.production_year,
    md.cast_names,
    md.total_keywords,
    CASE 
        WHEN md.total_keywords > 10 THEN 'High Keywords'
        WHEN md.total_keywords BETWEEN 6 AND 10 THEN 'Moderate Keywords'
        ELSE 'Low Keywords'
    END AS keyword_strength
FROM 
    MovieDetails md
WHERE 
    md.production_year = (SELECT MAX(production_year) FROM MovieRelease)
ORDER BY 
    md.total_keywords DESC;
