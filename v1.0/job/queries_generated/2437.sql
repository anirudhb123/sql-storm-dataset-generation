WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rnk
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rnk <= 5
),
ActorsWithAwards AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT p.info) AS awards_count
    FROM 
        aka_name a
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'award')
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    COALESCE(a.awards_count, 0) AS awards_count
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info c ON tm.id = c.movie_id
LEFT JOIN 
    ActorsWithAwards a ON c.person_id = a.person_id
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC
UNION ALL
SELECT 
    'Total Movies' AS title,
    NULL AS production_year,
    NULL AS actor_name,
    COUNT(*) AS awards_count
FROM 
    ActorsWithAwards;
