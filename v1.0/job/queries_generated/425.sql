WITH RankedMovies AS (
    SELECT 
        t.id as title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        ak.person_id,
        COUNT(DISTINCT c.movie_id) as movie_count,
        AVG(m.produced_years_diff) as avg_years_diff
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN (
        SELECT 
            title.id, 
            EXTRACT(YEAR FROM CURRENT_DATE) - title.production_year as produced_years_diff
        FROM 
            title
    ) m ON c.movie_id = m.id
    GROUP BY 
        ak.person_id
),
BestPerformingActors AS (
    SELECT 
        a.person_id,
        a.movie_count,
        a.avg_years_diff,
        RANK() OVER (ORDER BY a.movie_count DESC, a.avg_years_diff ASC) as actor_rank
    FROM 
        ActorStats a
)
SELECT 
    ak.name,
    t.title,
    t.production_year,
    CASE 
        WHEN b.actor_rank <= 10 THEN 'Top 10 Actor'
        ELSE 'Other Actor'
    END as actor_category,
    COALESCE(n.name, 'Unknown') as nickname
FROM 
    BestPerformingActors b
JOIN 
    aka_name ak ON b.person_id = ak.person_id 
LEFT JOIN 
    cast_info c ON ak.person_id = c.person_id 
LEFT JOIN 
    title t ON c.movie_id = t.id 
LEFT JOIN 
    name n ON ak.id = n.imdb_id 
WHERE 
    t.production_year IS NOT NULL
    AND b.movie_count > 5
ORDER BY 
    t.production_year DESC, 
    actor_category, 
    ak.name;
