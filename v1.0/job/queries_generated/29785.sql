WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actors
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)

SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    tm.actor_count AS Number_of_Actors,
    tm.actors AS Actors_List,
    kt.kind AS Movie_Kind,
    mt.info AS Movie_Info
FROM 
    top_movies tm
JOIN 
    kind_type kt ON (SELECT kind_id FROM aka_title WHERE id = tm.movie_id) = kt.id
LEFT JOIN 
    movie_info mt ON tm.movie_id = mt.movie_id AND mt.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
