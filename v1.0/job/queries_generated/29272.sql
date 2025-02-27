WITH MovieAverages AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        AVG(mci.info_length) AS average_info_length
    FROM 
        title
    JOIN 
        movie_info mci ON title.id = mci.movie_id
    GROUP BY 
        title.id
),
TopActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.person_id) AS roles_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
PopularMovies AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
    HAVING 
        COUNT(DISTINCT k.keyword) > 10
),
FinalResults AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.actor_name,
        ma.average_info_length,
        pm.keyword_count
    FROM 
        title t
    LEFT JOIN 
        TopActors a ON t.id = a.movie_id
    LEFT JOIN 
        MovieAverages ma ON t.id = ma.movie_id
    LEFT JOIN 
        PopularMovies pm ON t.id = pm.movie_id
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actor_name,
    COALESCE(average_info_length, 0) AS average_info_length,
    COALESCE(keyword_count, 0) AS keyword_count
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    keyword_count DESC;
