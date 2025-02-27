WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopRankedMovies AS (
    SELECT * FROM RankedMovies WHERE rank <= 5
), 
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title_id,
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(aka.name, 'Unknown') AS aka_name
FROM 
    TopRankedMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.movie_id
LEFT JOIN 
    aka_title at ON tm.title_id = at.movie_id
LEFT JOIN 
    aka_name aka ON at.id = aka.id
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
