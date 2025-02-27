WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS yearly_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
FilteredTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rt
    LEFT JOIN 
        ActorCount ac ON rt.movie_id = ac.movie_id
    WHERE 
        rt.yearly_rank <= 5
)
SELECT 
    ft.title,
    ft.production_year,
    ft.actor_count,
    CASE 
        WHEN ft.actor_count > 10 THEN 'Highly Casted'
        WHEN ft.actor_count > 0 THEN 'Moderately Casted'
        ELSE 'No Cast'
    END AS casting_category
FROM 
    FilteredTitles ft
WHERE 
    ft.actor_count IS NOT NULL 
ORDER BY 
    ft.production_year DESC, 
    ft.actor_count DESC
LIMIT 20;
