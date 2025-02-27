WITH MovieStats AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
        STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name cn ON c.person_id = cn.person_id
    GROUP BY 
        a.id
),
TopMovies AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.actor_count,
        ms.avg_order,
        RANK() OVER (PARTITION BY ms.production_year ORDER BY ms.actor_count DESC) AS rank_per_year
    FROM 
        MovieStats ms
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.avg_order,
    CASE
        WHEN tm.actor_count IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_status
FROM 
    TopMovies tm
WHERE 
    tm.rank_per_year <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;

-- Bonus: Check for movies without any keywords
SELECT 
    m.title,
    m.production_year,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    CASE
        WHEN mk.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status
FROM 
    aka_title m
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(keyword_id) AS keyword_count 
    FROM 
        movie_keyword 
    GROUP BY 
        movie_id
) mk ON m.id = mk.movie_id
ORDER BY 
    m.production_year;
