WITH MovieData AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        CAST(COUNT(DISTINCT c.person_id) AS INTEGER) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
ActorAwards AS (
    SELECT 
        person_id,
        COUNT(DISTINCT mi.movie_id) AS award_movies_count
    FROM 
        person_info pi
    INNER JOIN 
        movie_info mi ON pi.person_id = mi.movie_id 
    WHERE 
        pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards')
    GROUP BY 
        person_id
),
TopMovies AS (
    SELECT 
        m.movie_title,
        m.production_year,
        m.num_actors,
        COALESCE(a.award_movies_count, 0) AS award_count
    FROM 
        MovieData m
    LEFT JOIN 
        ActorAwards a ON m.actor_name = (SELECT name FROM aka_name WHERE person_id = a.person_id LIMIT 1)
    WHERE 
        m.rank <= 10
)
SELECT 
    movie_title,
    production_year,
    num_actors,
    award_count
FROM 
    TopMovies
WHERE 
    num_actors IS NOT NULL 
    AND (production_year BETWEEN 2010 AND 2020 OR award_count > 0)
ORDER BY 
    num_actors DESC, award_count DESC;
