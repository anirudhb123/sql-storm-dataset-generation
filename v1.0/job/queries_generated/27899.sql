WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        AVG(CASE WHEN cc.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles
    FROM 
        aka_title m
        JOIN movie_keyword mk ON m.id = mk.movie_id
        JOIN keyword k ON mk.keyword_id = k.id
        LEFT JOIN complete_cast cc ON m.id = cc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count,
        avg_roles,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_by_cast
    FROM 
        RankedMovies
)

SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.cast_count,
    tm.avg_roles,
    p.name AS main_actor,
    i.info AS plot_info
FROM 
    TopMovies tm
    JOIN cast_info ci ON tm.movie_id = ci.movie_id
    JOIN aka_name p ON ci.person_id = p.person_id
    JOIN movie_info i ON tm.movie_id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    tm.rank_by_cast <= 3
ORDER BY 
    tm.production_year, cast_count DESC;
