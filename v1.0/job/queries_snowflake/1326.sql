
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
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
        rank_in_year <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    mk.keywords,
    (SELECT 
         COUNT(DISTINCT c.person_id) 
     FROM 
         cast_info c 
     WHERE 
         c.movie_id = tm.movie_id AND c.note IS NOT NULL) AS distinct_cast_with_note,
    COALESCE(p.info, 'No Info Available') AS person_info
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    (SELECT 
         pi.person_id,
         LISTAGG(pi.info, '; ') WITHIN GROUP (ORDER BY pi.info) AS info
     FROM 
         person_info pi
     WHERE 
         pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
     GROUP BY 
         pi.person_id) p ON p.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = tm.movie_id)
ORDER BY 
    tm.production_year DESC, 
    tm.title;
