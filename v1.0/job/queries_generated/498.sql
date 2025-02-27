WITH MovieRatings AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        AVG(r.rating) AS avg_rating
    FROM 
        title m
    LEFT JOIN 
        (SELECT movie_id, rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) r
    ON 
        m.id = r.movie_id
    GROUP BY 
        m.id, m.title
),
FilteredMovies AS (
    SELECT 
        mr.movie_id,
        mr.title,
        CASE 
            WHEN mr.avg_rating IS NULL THEN 'Not Rated'
            WHEN mr.avg_rating >= 8 THEN 'Highly Rated'
            WHEN mr.avg_rating >= 5 THEN 'Moderately Rated'
            ELSE 'Lowly Rated'
        END AS rating_category
    FROM 
        MovieRatings mr
)
SELECT 
    fm.title,
    fm.rating_category,
    COUNT(DISTINCT ca.person_id) AS num_actors,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    MAX(COALESCE(ct.kind, 'No Company')) AS company_type
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info ca ON fm.movie_id = ca.movie_id
LEFT JOIN 
    aka_name a ON ca.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    fm.movie_id, fm.title, fm.rating_category
HAVING 
    COUNT(DISTINCT ca.person_id) > 5
ORDER BY 
    fm.avg_rating DESC NULLS LAST, fm.title;
