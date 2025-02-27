WITH MovieStats AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(COUNT(DISTINCT c.person_id), 0) AS actor_count,
        COALESCE(SUM(CASE WHEN cm.kind_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS company_count,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name cm ON mc.company_id = cm.id
    LEFT JOIN 
        movie_keyword k ON a.id = k.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id
),
RankedMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC, title ASC) AS rank_by_actors
    FROM 
        MovieStats
),
TopMovies AS (
    SELECT 
        *
    FROM 
        RankedMovies
    WHERE 
        rank_by_actors <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.actor_count,
    tm.company_count,
    tm.keywords,
    ROUND((tm.actor_count::decimal / NULLIF(tm.company_count, 0)), 2) AS actor_to_company_ratio
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
