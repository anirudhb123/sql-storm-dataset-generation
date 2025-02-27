
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
        a.title, a.production_year
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
