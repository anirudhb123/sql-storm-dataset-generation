WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        actors,
        RANK() OVER (ORDER BY cast_count DESC) AS movie_rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    CASE 
        WHEN tm.movie_rank <= 10 THEN 'Top 10 Cast Movies'
        ELSE 'Other Movies'
    END AS classification
FROM 
    TopMovies tm
WHERE 
    tm.production_year >= 2000
    AND tm.cast_count > (
        SELECT 
            AVG(cast_count)
        FROM 
            (SELECT 
                COUNT(DISTINCT c.person_id) AS cast_count
            FROM 
                aka_title t
            JOIN 
                cast_info c ON t.id = c.movie_id
            GROUP BY 
                t.id) AS averages
    )
ORDER BY 
    tm.cast_count DESC
LIMIT 20;
