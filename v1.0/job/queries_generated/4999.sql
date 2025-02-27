WITH MovieDetails AS (
    SELECT
        at.title AS movie_title,
        at.production_year,
        STRING_AGG(CONCAT(an.name, ' (', rt.role, ')'), ', ') AS full_cast,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(mi.info::numeric) AS average_rating
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN
        movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY
        at.id, at.title, at.production_year
),
HighRatedMovies AS (
    SELECT
        movie_title,
        production_year,
        full_cast,
        company_count,
        average_rating
    FROM
        MovieDetails
    WHERE
        average_rating IS NOT NULL AND average_rating > 8.0
)
SELECT 
    h.movie_title,
    h.production_year,
    h.full_cast,
    h.company_count,
    COALESCE(h.average_rating, 'Not Rated') AS average_rating,
    CASE 
        WHEN h.company_count > 5 THEN 'High Production'
        WHEN h.company_count BETWEEN 3 AND 5 THEN 'Moderate Production'
        ELSE 'Low Production'
    END AS production_category
FROM 
    HighRatedMovies h
WHERE 
    h.production_year BETWEEN 2000 AND 2023
ORDER BY 
    h.average_rating DESC, h.production_year DESC;
