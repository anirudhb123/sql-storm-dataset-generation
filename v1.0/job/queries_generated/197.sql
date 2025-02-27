WITH MovieData AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        MovieData
    WHERE 
        actor_count > 5
)
SELECT 
    t.title,
    t.production_year,
    t.actor_count,
    t.actor_names,
    COALESCE(DISTINCT m.info, 'No additional info') AS movie_info
FROM 
    TopMovies t
LEFT JOIN 
    movie_info m ON t.title = m.info AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    t.rank <= 10
ORDER BY 
    t.rank;
