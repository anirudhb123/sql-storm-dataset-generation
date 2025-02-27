WITH RecursiveMovieCTE AS (
    SELECT t.id AS movie_id, t.title, t.production_year, 0 AS depth
    FROM aka_title t
    WHERE t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT t.id AS movie_id, t.title, t.production_year, r.depth + 1
    FROM aka_title t
    JOIN RecursiveMovieCTE r ON t.episode_of_id = r.movie_id
),
TopMovies AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        AVG(CASE WHEN c.role_id IS NULL THEN 0 ELSE 1 END) AS has_role
    FROM RecursiveMovieCTE m
    LEFT JOIN cast_info c ON m.movie_id = c.movie_id
    GROUP BY m.movie_id, m.title, m.production_year
),
RankedMovies AS (
    SELECT
        tm.*,
        RANK() OVER (ORDER BY tm.cast_count DESC, tm.production_year DESC) AS rank
    FROM TopMovies tm
)
SELECT
    r.title,
    r.production_year,
    CASE
        WHEN r.cast_count IS NULL THEN 'Unknown' 
        ELSE r.cast_count::text 
    END AS number_of_cast,
    CASE
        WHEN r.has_role IS NULL THEN 'Not Applicable' 
        ELSE r.has_role::text 
    END AS role_inclusion,
    COALESCE(p.info, 'No Info') AS personal_info
FROM RankedMovies r
LEFT JOIN person_info p ON p.person_id = (
    SELECT c.person_id
    FROM cast_info c
    WHERE c.movie_id = r.movie_id
    ORDER BY c.nr_order
    LIMIT 1
)
WHERE r.rank <= 10
ORDER BY r.rank;
