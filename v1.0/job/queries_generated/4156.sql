WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
), 
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.total_cast,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(m.keywords, 'No Keywords') AS keywords,
    COALESCE(p.first_name, 'Unknown') AS lead_actor_first_name,
    COALESCE(p.last_name, 'Unknown') AS lead_actor_last_name
FROM 
    MoviesWithKeywords m
LEFT JOIN 
    (SELECT 
        c.movie_id,
        a.name AS first_name,
        a.surname AS last_name
     FROM 
        cast_info c
     JOIN 
        aka_name a ON c.person_id = a.person_id
     WHERE 
        c.nr_order = 1) p ON m.movie_id = p.movie_id
ORDER BY 
    m.production_year DESC, m.total_cast DESC;
