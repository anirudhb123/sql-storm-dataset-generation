WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 10
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(COUNT(k.id), 0) AS keyword_count,
        COALESCE(AVG(mk.production_year), NULL) AS avg_keyword_year
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title
)
SELECT 
    md.title,
    md.production_year,
    COUNT(DISTINCT ca.person_id) AS total_cast,
    md.keyword_count,
    (SELECT COUNT(DISTINCT ci.id)
     FROM complete_cast ci
     WHERE ci.movie_id = md.movie_id AND ci.status_id IS NOT NULL) AS unique_complete_cast,
    CASE 
        WHEN md.avg_keyword_year IS NOT NULL THEN md.avg_keyword_year 
        ELSE (SELECT AVG(production_year) FROM aka_title) 
    END AS fallback_avg_year
FROM 
    MovieDetails md
JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.movie_id = ca.movie_id
GROUP BY 
    md.movie_id, md.title, md.keyword_count, md.production_year
HAVING 
    COUNT(DISTINCT ca.person_id) > 2
ORDER BY 
    md.keyword_count DESC, md.title;
