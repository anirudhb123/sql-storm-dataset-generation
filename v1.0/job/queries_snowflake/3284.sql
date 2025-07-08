
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COALESCE(b.nr_order, 999) ASC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info b ON a.id = b.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
LatestMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
Genres AS (
    SELECT 
        m.title,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        LatestMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)
SELECT 
    lm.title,
    lm.production_year,
    COALESCE(g.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_count
FROM 
    LatestMovies lm
LEFT JOIN 
    cast_info ci ON lm.movie_id = ci.movie_id
LEFT JOIN 
    Genres g ON lm.title = g.title
GROUP BY 
    lm.title, lm.production_year, g.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    lm.production_year DESC, lm.title;
