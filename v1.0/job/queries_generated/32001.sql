WITH RECURSIVE MovieTree AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        mk.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.level + 1
    FROM
        MovieTree mt
    JOIN
        movie_link mk ON mt.movie_id = mk.movie_id
    JOIN
        aka_title mt ON mk.linked_movie_id = mt.id
),
RankedMovies AS (
    SELECT
        m.*,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year, m.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL
),
TopMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.year_rank,
        rm.total_movies
    FROM
        RankedMovies rm
    WHERE
        rm.year_rank <= 5
)
SELECT
    ak.name AS actor_name,
    tm.title AS movie_title,
    tm.production_year,
    COUNT(DISTINCT cm.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    AVG(mi.info) FILTER (WHERE mi.note IS NOT NULL) AS average_movie_info,
    CASE 
        WHEN tm.production_year < 2010 THEN 'Old' 
        ELSE 'New' 
    END AS movie_age_category
FROM
    TopMovies tm
JOIN
    cast_info ci ON ci.movie_id = tm.movie_id
JOIN
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = ci.movie_id
LEFT JOIN
    company_name cn ON cn.id = mc.company_id
LEFT JOIN
    movie_info mi ON mi.movie_id = tm.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
GROUP BY
    ak.name, tm.title, tm.production_year
ORDER BY
    movie_age_category, tm.production_year DESC, COUNT(DISTINCT cm.company_id) DESC;
