
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_actors,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_actors <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        TopMovies m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT p.id) AS total_person_info,
    LISTAGG(DISTINCT p.info, '; ') WITHIN GROUP (ORDER BY p.info) AS person_info_details
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    person_info p ON p.person_id = mi.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.production_year BETWEEN 2000 AND 2023
GROUP BY 
    tm.title, tm.production_year, mk.keywords
HAVING 
    COUNT(DISTINCT p.id) > 0
ORDER BY 
    tm.production_year, total_person_info DESC;
