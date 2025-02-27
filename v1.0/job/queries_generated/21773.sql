WITH RecursiveMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    WHERE
        m.production_year IS NOT NULL
      AND m.production_year > 2000
),
PeopleWithRoles AS (
    SELECT
        ka.name AS actor_name,
        c.movie_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM
        cast_info c
    JOIN
        aka_name ka ON c.person_id = ka.person_id
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        r.role IS NOT NULL
),
MoviesWithInfo AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(DISTINCT pw.actor_name, ', ') AS actors,
        COUNT(DISTINCT pw.role_name) AS role_types,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM
        RecursiveMovies rm
    LEFT JOIN
        PeopleWithRoles pw ON rm.movie_id = pw.movie_id
    LEFT JOIN
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN
        movie_keyword mk ON rm.movie_id = mk.movie_id
    GROUP BY
        rm.movie_id, rm.title, rm.production_year
),
BestMovies AS (
    SELECT 
        m.title,
        m.production_year,
        m.actors,
        m.role_types,
        m.keyword_count,
        RANK() OVER (ORDER BY m.keyword_count DESC, m.role_types DESC) AS ranking
    FROM 
        MoviesWithInfo m
)
SELECT 
    bm.title,
    bm.production_year,
    bm.actors,
    bm.role_types,
    bm.keyword_count,
    CASE 
        WHEN bm.keyword_count > 10 THEN 'Highly Tagged'
        WHEN bm.keyword_count BETWEEN 5 AND 10 THEN 'Moderately Tagged'
        ELSE 'Less Tagged'
    END AS tagging_status,
    COALESCE((
        SELECT COUNT(*) 
        FROM complete_cast cc 
        WHERE cc.movie_id = bm.movie_id AND cc.status_id IS NULL
    ), 0) AS incomplete_cast_count
FROM 
    BestMovies bm
WHERE 
    bm.ranking <= 10
ORDER BY 
    bm.ranking, bm.production_year DESC;
