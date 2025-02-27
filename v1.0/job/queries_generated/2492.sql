WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieCast AS (
    SELECT 
        m.movie_id,
        COUNT(CASE WHEN c.role_id = (SELECT id FROM role_type WHERE role = 'actor') THEN 1 END) AS actor_count,
        COUNT(CASE WHEN c.role_id = (SELECT id FROM role_type WHERE role = 'director') THEN 1 END) AS director_count
    FROM 
        complete_cast m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mc.actor_count, 0) AS total_actors,
    COALESCE(mc.director_count, 0) AS total_directors,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT CASE WHEN ci.note IS NOT NULL THEN ci.note END) AS unique_notes_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rank <= 10 AND (rm.production_year IS NOT NULL AND rm.production_year > 2000)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, mc.actor_count, mc.director_count, mk.keywords
ORDER BY 
    rm.production_year DESC, total_actors DESC;
