WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_count_rank
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
        actor_count_rank <= 5
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
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS unique_actor_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.movie_id AND mi.info_type_id = 1) AS info_count
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, mk.keywords
ORDER BY 
    tm.production_year DESC, unique_actor_count DESC;
