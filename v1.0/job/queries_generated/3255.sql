WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    COALESCE(km.keywords, 'No Keywords') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordMovies km ON md.title = (SELECT title FROM title WHERE id = km.movie_id)
WHERE 
    md.production_year IN (SELECT production_year FROM RankedMovies WHERE rn <= 5)
ORDER BY 
    md.production_year DESC, md.total_cast DESC;
