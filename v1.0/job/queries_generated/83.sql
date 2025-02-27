WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
HighlyRatedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ROUND(AVG(rating), 2), 0) AS avg_rating
    FROM 
        title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY m.id, m.title, m.production_year
    HAVING COUNT(mi.id) > 0
)
SELECT 
    r.title,
    r.production_year,
    r.total_cast,
    h.avg_rating
FROM RankedMovies r
INNER JOIN HighlyRatedMovies h ON r.title_id = h.movie_id
WHERE r.rank <= 5
ORDER BY h.avg_rating DESC, r.total_cast ASC
LIMIT 10;

-- Additional complex filtering
UNION ALL

SELECT 
    t.title,
    t.production_year,
    (SELECT COUNT(*) FROM cast_info c WHERE c.movie_id = t.id) AS total_cast,
    NULL AS avg_rating 
FROM title t
WHERE t.production_year IS NULL AND EXISTS (
    SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = t.id AND mk.keyword_id IN (
        SELECT id FROM keyword WHERE keyword LIKE '%action%'
    )
)
ORDER BY total_cast DESC
LIMIT 5;
