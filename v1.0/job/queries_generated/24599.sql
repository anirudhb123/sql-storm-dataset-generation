WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS ranked_title,
        COUNT(ci.person_id) AS cast_count,
        COUNT(DISTINCT CASE WHEN ci.note IS NOT NULL THEN ci.person_id END) AS non_null_actors
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON ci.movie_id = t.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
GenreMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        kt.kind AS genre
    FROM 
        aka_title AS m
    JOIN 
        kind_type AS kt ON m.kind_id = kt.id
),
Directors AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS directors_list
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.ranked_title,
    gm.genre,
    rm.cast_count,
    rm.non_null_actors,
    d.directors_list,
    CASE 
        WHEN rm.cast_count = 0 THEN 'No Cast' 
        WHEN rm.non_null_actors = 0 THEN 'No Valid Cast' 
        ELSE 'Casts Available' 
    END AS cast_status,
    (SELECT COUNT(*) 
     FROM movie_info AS mi 
     WHERE mi.movie_id = rm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_count
FROM 
    RankedMovies AS rm
LEFT JOIN 
    GenreMovies AS gm ON rm.movie_id = gm.movie_id
LEFT JOIN 
    Directors AS d ON rm.movie_id = d.movie_id
WHERE 
    rm.cast_count > 0 
    AND (rm.production_year > 2000 
    OR EXISTS (SELECT 1 
                FROM keyword AS k 
                JOIN movie_keyword AS mk ON k.id = mk.keyword_id 
                WHERE mk.movie_id = rm.movie_id AND k.keyword LIKE '%Action%'))
ORDER BY 
    rm.production_year DESC, 
    rm.title;


This SQL query constructs a performance benchmark through various advanced SQL techniques: Common Table Expressions (CTEs) for organized subqueries, window functions for ranking, and outer joins for comprehensive data inclusion. The query filters results based on specific conditions, dynamically calculates cast-related metrics, and provides nuanced insights into the cast status and ratings.
