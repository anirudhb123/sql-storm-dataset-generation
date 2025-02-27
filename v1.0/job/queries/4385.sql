WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
),
MovieKeywords AS (
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
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'None') AS keywords,
    NULLIF(tm.production_year % 2, 0) AS is_even_year,
    (SELECT AVG(r.id) 
     FROM role_type r 
     WHERE r.role LIKE '%Lead%') AS avg_lead_role_id,
    COUNT(DISTINCT c.person_id) AS unique_cast_members,
    CASE 
        WHEN COUNT(c.id) > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info c ON tm.movie_id = c.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
GROUP BY 
    tm.title, tm.production_year, mk.keywords
ORDER BY 
    tm.production_year DESC, 
    unique_cast_members DESC;
