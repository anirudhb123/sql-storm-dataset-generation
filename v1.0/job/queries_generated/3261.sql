WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    INNER JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        rn,
        total_movies,
        (total_movies - rn + 1) AS remaining_movies
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
)
SELECT 
    f.title,
    f.production_year,
    f.remaining_movies,
    COALESCE(NULLIF(SUBSTRING(f.title FROM '%[^[:alnum:]]'), ''), 'No Title') AS title_status,
    CONCAT('Year ', f.production_year, ' has ', f.remaining_movies, ' movies ranked below') AS movie_summary
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.rn;
