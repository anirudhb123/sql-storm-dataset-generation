WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        AVG(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
                 THEN CAST(pi.info AS DECIMAL) 
                 ELSE NULL END) AS average_rating
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        person_info pi ON ci.person_id = pi.person_id
    GROUP BY 
        m.id, m.title
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.cast_names,
    md.average_rating,
    COALESCE(mr.year_rank, 0) AS year_rank
FROM 
    MovieDetails md
LEFT JOIN 
    RankedMovies mr ON md.production_year = mr.production_year
WHERE 
    md.average_rating IS NOT NULL
ORDER BY 
    md.production_year DESC, md.average_rating DESC
LIMIT 50;
