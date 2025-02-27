WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.id) AS cast_ids,
        COUNT(DISTINCT c.id) AS cast_count
    FROM title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON m.id = c.movie_id
    WHERE m.production_year BETWEEN 2000 AND 2023
    GROUP BY m.id, m.title, m.production_year
),
TopCast AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.movie_keyword,
        r.cast_count,
        ROW_NUMBER() OVER (PARTITION BY r.production_year ORDER BY r.cast_count DESC) AS rank
    FROM RankedMovies r
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    t.movie_keyword,
    t.cast_count,
    ak.name AS actor_name,
    ak.imdb_index,
    rt.role AS role
FROM TopCast t
JOIN complete_cast cc ON t.movie_id = cc.movie_id
JOIN aka_name ak ON cc.subject_id = ak.person_id
JOIN role_type rt ON cc.role_id = rt.id
WHERE t.rank <= 5
ORDER BY t.production_year DESC, t.cast_count DESC;
