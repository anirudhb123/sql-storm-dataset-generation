WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS movie_rank,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
PopularActors AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT c.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.id, ak.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
HighRatedMovies AS (
    SELECT 
        mv.id,
        mv.title,
        mv.production_year,
        mi.info AS rating 
    FROM 
        title mv
    LEFT JOIN 
        movie_info mi ON mv.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        mv.production_year > 2000
        AND (mi.info IS NULL OR mi.info::numeric >= 7.0)
)
SELECT 
    r.title AS movie_title,
    r.production_year,
    r.cast_count,
    a.name AS popular_actor,
    COALESCE(h.rating, 'No Rating') AS movie_rating
FROM 
    RankedMovies r
LEFT JOIN 
    PopularActors a ON r.cast_count = a.movies_count
LEFT JOIN 
    HighRatedMovies h ON r.title = h.title AND r.production_year = h.production_year
WHERE 
    r.movie_rank <= 5
ORDER BY 
    r.production_year DESC, r.cast_count DESC;
