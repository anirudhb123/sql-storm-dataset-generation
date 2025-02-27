
WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
KeywordCTE AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(kw.keyword_count, 0) AS keyword_count,
        m.cast_count
    FROM 
        MovieCTE m
    LEFT JOIN 
        KeywordCTE kw ON m.movie_id = kw.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    md.cast_count
FROM 
    MovieDetails md
WHERE 
    md.cast_count >= 5
AND 
    md.keyword_count > 0
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 50;
