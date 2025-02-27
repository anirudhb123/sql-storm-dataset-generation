WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        total_cast_members,
        actor_names 
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast_members,
    tm.actor_names,
    k.keyword AS movie_keyword,
    ct.kind AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast_members DESC;

This SQL query identifies the top five movies with the most cast members per production year, retrieves the actor names for these movies, and associates each movie with its keywords and corresponding company types, providing a comprehensive overview suitable for benchmarking string processing in a relational database context.
