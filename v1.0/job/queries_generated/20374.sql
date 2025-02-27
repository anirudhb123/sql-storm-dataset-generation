WITH RecursiveMovieRatings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        AVG(pi.info::numeric) AS average_rating
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info = 'rating'
    GROUP BY 
        t.id, t.title
),
UnusualRoleDistribution AS (
    SELECT 
        ci.role_id,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        cast_info ci
    GROUP BY 
        ci.role_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 1
),
QualifiedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(r.average_rating, 0) AS avg_rating,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        title t
    LEFT JOIN 
        RecursiveMovieRatings r ON t.id = r.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND (t.title LIKE '%A%' OR t.title LIKE '%B%')
    GROUP BY 
        t.id, t.title, r.average_rating
)
SELECT 
    qm.title,
    qm.avg_rating,
    CASE 
        WHEN qm.total_cast > 10 
            THEN 'Large Cast'
        WHEN qm.total_cast BETWEEN 5 AND 10 
            THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    COALESCE(cn.name, 'Unknown') AS company_name,
    COUNT(k.keyword) AS total_keywords
FROM 
    QualifiedMovies qm
LEFT JOIN 
    movie_companies mc ON qm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON qm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    qm.avg_rating > 7.0 
    OR (qm.title ILIKE '%special%' AND qm.total_cast < 5)
GROUP BY 
    qm.title, qm.avg_rating, cn.name
HAVING 
    SUM(CASE WHEN qm.avg_rating IS NULL THEN 1 ELSE 0 END) = 0
ORDER BY 
    avg_rating DESC, qm.title;
