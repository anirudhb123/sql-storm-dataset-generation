WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CategorizedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actors,
        rm.keywords,
        CASE 
            WHEN rm.cast_count > 10 THEN 'Ensemble'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Moderate'
            ELSE 'Small'
        END AS cast_category
    FROM 
        RankedMovies rm
)
SELECT 
    cm.title,
    cm.production_year,
    cm.cast_count,
    cm.actors,
    cm.keywords,
    cm.cast_category
FROM 
    CategorizedMovies cm
WHERE 
    cm.cast_category = 'Ensemble'
ORDER BY 
    cm.production_year DESC, 
    cm.cast_count DESC
LIMIT 10;
