WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year,
        COALESCE(ki.keyword, 'Unknown') AS keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MIN(c.nr_order) AS first_cast_order,
        MAX(c.nr_order) AS last_cast_order
    FROM 
        complete_cast m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.keyword,
    mc.total_cast,
    mc.first_cast_order,
    mc.last_cast_order,
    CASE 
        WHEN mc.total_cast > 5 THEN 'Large Cast'
        WHEN mc.total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size
FROM 
    RankedMovies r
LEFT JOIN 
    MovieCast mc ON r.movie_id = mc.movie_id
WHERE 
    r.rank_by_year > 10
ORDER BY 
    r.production_year DESC, mc.total_cast DESC
LIMIT 20;