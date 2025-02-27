
WITH MovieStats AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names,
        t.id AS movie_id
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name n ON c.person_id = n.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
FinalStats AS (
    SELECT 
        ms.movie_title,
        ms.production_year,
        ms.cast_count,
        ms.cast_names,
        COALESCE(ks.keyword_count, 0) AS keyword_count,
        ks.keywords,
        ms.movie_id
    FROM 
        MovieStats ms
    LEFT JOIN 
        KeywordStats ks ON ms.movie_id = ks.movie_id
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    cast_names,
    keyword_count,
    keywords
FROM 
    FinalStats
ORDER BY 
    production_year DESC, cast_count DESC;
