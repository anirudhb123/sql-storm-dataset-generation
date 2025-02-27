WITH RecursiveFilmography AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_seq
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT CASE WHEN kp.keyword IS NOT NULL THEN kp.keyword END) AS keyword_count,
        COALESCE(MIN(mn.note), 'No notes') AS movie_note
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kp ON mk.keyword_id = kp.id
    LEFT JOIN 
        movie_info mn ON t.id = mn.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS total_movies
    FROM 
        RecursiveFilmography
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        total_movies,
        RANK() OVER (ORDER BY total_movies DESC) AS actor_rank
    FROM 
        ActorCount
    WHERE 
        total_movies > 5
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword_count,
    tar.actor_name,
    tar.total_movies,
    CASE 
        WHEN md.keyword_count >= 5 THEN 'Popular'
        WHEN md.keyword_count BETWEEN 1 AND 4 THEN 'Moderate'
        ELSE 'Unknown'
    END AS movie_type,
    CASE 
        WHEN md.movie_note IS NULL THEN 'No notes available'
        ELSE md.movie_note
    END AS processed_note
FROM 
    MovieDetails md
INNER JOIN 
    RecursiveFilmography rf ON md.movie_id = rf.movie_id
INNER JOIN 
    TopActors tar ON rf.actor_name = tar.actor_name
WHERE 
    md.production_year > (SELECT AVG(production_year) FROM aka_title)
   OR md.movie_id IN (SELECT movie_id FROM movie_info WHERE info LIKE '%Award%')
ORDER BY 
    md.production_year DESC, tar.total_movies DESC 
LIMIT 10;
