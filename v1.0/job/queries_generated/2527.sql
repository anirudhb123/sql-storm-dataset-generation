WITH movie_ratings AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        AVG(r.rating) AS average_rating
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT 
            movie_id, 
            AVG(rating_value) AS rating 
        FROM 
            ratings 
        GROUP BY 
            movie_id) r ON mt.movie_id = r.movie_id
    GROUP BY 
        mt.id, mt.title
),
cast_aggregate AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
production_companies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mt.title,
    mt.production_year,
    COALESCE(r.average_rating, 'N/A') AS average_rating,
    COALESCE(c.total_cast, 0) AS total_cast,
    COALESCE(c.cast_names, 'No cast') AS cast_names,
    COALESCE(p.total_companies, 0) AS total_companies
FROM 
    aka_title mt
LEFT JOIN 
    movie_ratings r ON mt.id = r.movie_id
LEFT JOIN 
    cast_aggregate c ON mt.id = c.movie_id
LEFT JOIN 
    production_companies p ON mt.id = p.movie_id
WHERE 
    mt.production_year >= 2000
    AND (r.average_rating IS NULL OR r.average_rating >= 7.0)
ORDER BY 
    mt.production_year DESC, 
    r.average_rating DESC NULLS LAST;
