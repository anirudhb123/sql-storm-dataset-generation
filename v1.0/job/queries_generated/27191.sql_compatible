
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT a.id) DESC) AS year_rank
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_names,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    pm.title,
    pm.production_year,
    pm.cast_names,
    pm.keyword_count,
    GROUP_CONCAT(DISTINCT ci.note) AS cast_notes,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    PopularMovies pm
LEFT JOIN 
    complete_cast cc ON pm.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON pm.movie_id = mc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
GROUP BY 
    pm.movie_id, pm.title, pm.production_year, pm.cast_names, pm.keyword_count
ORDER BY 
    pm.production_year DESC, pm.keyword_count DESC;
