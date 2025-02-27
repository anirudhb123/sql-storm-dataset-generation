WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(c.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%') 
    GROUP BY 
        t.id, a.name
),

MostCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_name,
        total_cast,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    mm.movie_id,
    mm.title,
    mm.production_year,
    ARRAY_AGG(mm.actor_name ORDER BY mm.actor_name) AS cast_members,
    mm.total_cast
FROM 
    MostCastMovies mm
WHERE 
    mm.rank <= 10
GROUP BY 
    mm.movie_id, mm.title, mm.production_year, mm.total_cast
ORDER BY 
    mm.total_cast DESC;

This query ranks movies based on the total number of cast members, and selects the top 10 movies with the most cast, aggregating their actor names into a single array for easier analysis. It effectively showcases string processing through concatenation and the use of window functions.
