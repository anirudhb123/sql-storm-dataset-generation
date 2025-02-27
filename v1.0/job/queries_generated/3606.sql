WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) OVER(PARTITION BY a.id) AS actor_count,
        AVG(CASE WHEN a.production_year IS NOT NULL THEN a.production_year ELSE 0 END) OVER() AS avg_production_year
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        a.production_year >= 2000
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%')
),
HighlyRatedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        avg_production_year,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.actor_count,
    m.avg_production_year,
    (SELECT STRING_AGG(c.name, ', ') 
     FROM cast_info ci
     JOIN aka_name c ON ci.person_id = c.person_id
     WHERE ci.movie_id = m.movie_id) AS actors_list,
    COALESCE(m.rank, 0) AS movie_rank
FROM 
    HighlyRatedMovies m
FULL OUTER JOIN 
    movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
WHERE 
    mi.info IS NOT NULL
ORDER BY 
    m.actor_count DESC, m.production_year ASC
LIMIT 100;
