WITH MovieData AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        a.md5sum AS actor_md5,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT g.name) AS genre_list
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        (SELECT 
            mi.movie_id, 
            GROUP_CONCAT(DISTINCT it.info SEPARATOR ', ') AS name_genres 
         FROM 
            movie_info mi 
         JOIN 
            info_type it ON mi.info_type_id = it.id 
         WHERE 
            it.info = 'genre' 
         GROUP BY 
            mi.movie_id) g ON g.movie_id = m.id
    WHERE 
        m.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword, a.name, a.md5sum, c.kind
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    movie_keyword,
    actor_name,
    actor_md5,
    company_type,
    genre_list
FROM 
    MovieData
ORDER BY 
    production_year DESC, 
    movie_title ASC;

This SQL query extracts extensive information about movies, including their titles, production years, associated keywords, acting cast, and production companies, along with a list of genres derived from the movie's information. It groups results by various attributes to avoid redundancy while aiming to provide an informative overview of movies released between 1990 and 2023.
