WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
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
), 
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rank_per_year <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(tm.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')) AS box_office_info,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = tm.movie_id AND cc.status_id IS NOT NULL) AS complete_cast_count
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
