WITH MovieData AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        *,
        CASE 
            WHEN total_cast > 5 THEN 'Popular'
            ELSE 'Less Popular'
        END AS popularity
    FROM 
        MovieData
    WHERE 
        rn <= 10
)
SELECT 
    m.title,
    m.production_year,
    m.total_cast,
    m.cast_names,
    m.popularity,
    COALESCE(i.info, 'No additional info available') AS additional_info
FROM 
    TopMovies m
LEFT JOIN 
    movie_info i ON m.title = i.info AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    m.popularity = 'Popular'
ORDER BY 
    m.production_year DESC, 
    m.total_cast DESC
LIMIT 20;
