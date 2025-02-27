WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        STRING_AGG(DISTINCT CONCAT(c.name, ' as ', r.role), ', ') AS cast_list,
        COUNT(DISTINCT m.id) AS company_count
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies m ON a.id = m.movie_id
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        a.id, a.title, a.production_year
),
HighRatedMovies AS (
    SELECT 
        m.movie_id,
        AVG(score.info::numeric) AS average_score
    FROM 
        movie_info m
    JOIN 
        info_type i ON m.info_type_id = i.id
    WHERE 
        i.info = 'rating'
        AND m.info IS NOT NULL
    GROUP BY 
        m.movie_id
    HAVING 
        AVG(score.info::numeric) > 7.5
),
MoviesWithCompanies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.cast_list,
        COALESCE(hm.average_score, 0) AS average_rating
    FROM 
        MovieDetails md
    LEFT JOIN 
        HighRatedMovies hm ON md.production_year = hm.movie_id
    ORDER BY 
        md.production_year DESC
)
SELECT 
    movie_title,
    production_year,
    cast_list,
    CASE 
        WHEN average_rating IS NULL THEN 'No Rating'
        ELSE average_rating::text 
    END AS movie_rating
FROM 
    MoviesWithCompanies
WHERE 
    cast_list IS NOT NULL
UNION ALL
SELECT 
    'TOTAL' AS movie_title,
    NULL AS production_year,
    NULL AS cast_list,
    AVG(average_rating) FROM MoviesWithCompanies
WHERE 
    average_rating IS NOT NULL;
