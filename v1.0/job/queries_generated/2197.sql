WITH movie_details AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.id = c.movie_id
    LEFT JOIN 
        aka_name an ON c.person_id = an.person_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.id, at.title, at.production_year
),
high_rated_movies AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.cast_count
    FROM 
        movie_details md
    JOIN 
        movie_info mi ON md.title_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        AND mi.info::float >= 8.0
),
company_movies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    h.title,
    h.production_year,
    h.cast_count,
    COALESCE(c.company_count, 0) AS company_count,
    h.actors
FROM 
    high_rated_movies h
LEFT JOIN 
    company_movies c ON h.title_id = c.movie_id
ORDER BY 
    h.production_year DESC, h.cast_count DESC
LIMIT 10;
