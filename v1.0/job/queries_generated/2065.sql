WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, LENGTH(at.title) DESC) as title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
MovieStats AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON cc.movie_id = mk.movie_id
    GROUP BY 
        c.movie_id
),
PopularMovies AS (
    SELECT 
        r.title,
        m.total_cast,
        m.total_keywords
    FROM 
        RankedTitles r
    JOIN 
        MovieStats m ON r.title = (SELECT title FROM aka_title WHERE id = m.movie_id)
    WHERE 
        r.title_rank = 1
)
SELECT 
    pm.title,
    pm.total_cast,
    pm.total_keywords,
    CASE 
        WHEN pm.total_cast >= 10 THEN 'Highly Casted'
        WHEN pm.total_cast BETWEEN 5 AND 9 THEN 'Moderately Casted'
        ELSE 'Lightly Casted' 
    END AS cast_category,
    COALESCE((SELECT AVG(total_cast) FROM MovieStats), 0) AS average_cast_size,
    (SELECT COUNT(*) FROM aka_title WHERE production_year >= 2000) AS recent_movies_count
FROM 
    PopularMovies pm
WHERE 
    pm.total_keywords > 5
ORDER BY 
    pm.total_cast DESC NULLS LAST
LIMIT 10;
