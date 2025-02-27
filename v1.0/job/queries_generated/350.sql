WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 10
),
ActorCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieRatings AS (
    SELECT 
        m.movie_id,
        COALESCE(AVG(r.rating), 0) AS average_rating
    FROM 
        movie_info m
    LEFT JOIN 
        (SELECT movie_id, info FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) r ON m.movie_id = r.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    ac.actor_count,
    mr.average_rating
FROM 
    TopMovies tm
LEFT JOIN 
    ActorCounts ac ON tm.movie_id = ac.movie_id
LEFT JOIN 
    MovieRatings mr ON tm.movie_id = mr.movie_id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    mr.average_rating DESC, 
    tm.production_year DESC;
