
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(LENGTH(a.title)) AS avg_title_length,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year >= 2000
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.title, a.production_year
),
PopularActors AS (
    SELECT 
        p.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        name p
    JOIN 
        cast_info c ON p.id = c.person_id
    WHERE 
        p.gender = 'M' 
        AND p.id IN (SELECT person_id FROM person_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Oscar Winner'))
    GROUP BY 
        p.id, p.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 3
)
SELECT 
    r.title,
    r.production_year,
    r.cast_count,
    r.avg_title_length,
    COALESCE(a.movie_count, 0) AS actor_movie_count
FROM 
    RankedMovies r
LEFT JOIN 
    PopularActors a ON a.movie_count >= r.cast_count
WHERE 
    r.rank_by_cast <= 5
ORDER BY 
    r.production_year DESC, r.cast_count DESC;
