WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank,
        COALESCE(b.person_role_id, 0) AS role_count
    FROM 
        aka_title a
    LEFT JOIN
        cast_info b ON a.id = b.movie_id
    WHERE 
        a.production_year IS NOT NULL
), 
genre_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.movie_title,
    r.production_year,
    r.rank,
    COALESCE(g.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS total_cast
FROM 
    ranked_movies r
LEFT JOIN 
    genre_keywords g ON r.id = g.movie_id
LEFT JOIN 
    cast_info ci ON r.movie_id = ci.movie_id
WHERE 
    r.role_count > 0
GROUP BY 
    r.movie_title, r.production_year, r.rank, g.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) > 3
ORDER BY 
    r.production_year DESC, r.rank;
