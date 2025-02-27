WITH MovieDetails AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        SUM(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE 0 END) AS total_info_length
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = at.movie_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.title, at.production_year
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count,
        actors,
        total_info_length,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    r.production_year,
    r.movie_title,
    r.cast_count,
    r.actors,
    r.total_info_length,
    CASE 
        WHEN r.cast_count IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_status
FROM 
    RankedMovies r
WHERE 
    r.rank <= 5 
    AND r.total_info_length > 0
ORDER BY 
    r.production_year DESC, 
    r.cast_count DESC
UNION ALL
SELECT 
    9999 AS production_year,
    'N/A' AS movie_title,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    NULL AS actors,
    0 AS total_info_length,
    'No Cast' AS cast_status
FROM 
    cast_info ci
WHERE 
    ci.person_id NOT IN (SELECT DISTINCT person_id FROM aka_name)
GROUP BY 
    ci.movie_id;

