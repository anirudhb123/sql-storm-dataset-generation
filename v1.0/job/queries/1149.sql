
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        co.name AS company_name,
        w.actor_count,
        m.production_year,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = m.id AND mi.info_type_id = 1) AS awards_count
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        ActorCounts w ON m.id = w.movie_id
    WHERE 
        co.country_code IS NOT NULL
)
SELECT 
    d.title,
    d.production_year,
    COALESCE(d.company_name, 'Unknown') AS company_name,
    d.actor_count,
    d.awards_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    DetailedMovieInfo d
LEFT JOIN 
    movie_keyword mkw ON d.movie_id = mkw.movie_id
LEFT JOIN 
    keyword k ON mkw.keyword_id = k.id
WHERE 
    d.actor_count > 0 AND
    (d.awards_count IS NULL OR d.awards_count > 2)
GROUP BY 
    d.title, d.production_year, d.company_name, d.actor_count, d.awards_count
HAVING 
    COUNT(*) > 10
ORDER BY 
    d.production_year DESC, 
    d.actor_count DESC;
