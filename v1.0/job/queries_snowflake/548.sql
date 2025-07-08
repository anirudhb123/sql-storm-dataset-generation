
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.movie_title,
    t.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    AVG(ci.nr_order) AS average_role_order,
    COUNT(DISTINCT ci.person_id) AS total_cast_members
FROM 
    TopMovies t
LEFT JOIN 
    complete_cast cc ON t.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    MovieKeywords mk ON t.movie_id = mk.movie_id
WHERE 
    t.production_year IS NOT NULL
GROUP BY 
    t.movie_id, t.movie_title, t.production_year, mk.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) >= 1
ORDER BY 
    t.production_year DESC, total_cast_members DESC;
