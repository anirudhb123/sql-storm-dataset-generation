WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT k.keyword) AS num_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        actors,
        num_keywords,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank_cast
    FROM 
        MovieDetails
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.actors,
    tm.num_keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank_cast <= 5
    AND tm.num_keywords > (
        SELECT 
            AVG(num_keywords) 
        FROM 
            MovieDetails
        WHERE 
            production_year = tm.production_year
    )
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC 
LIMIT 10;