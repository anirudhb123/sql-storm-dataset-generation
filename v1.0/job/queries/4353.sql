WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank,
        COALESCE(v.vote_count, 0) AS total_votes
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        (SELECT movie_id, COUNT(*) AS vote_count
         FROM movie_info
         WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
         GROUP BY movie_id) v ON a.id = v.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
), FilteredMovies AS (
    SELECT 
        title,
        production_year,
        actor_name,
        total_votes
    FROM 
        RankedMovies
    WHERE 
        total_votes > (SELECT AVG(total_votes) FROM RankedMovies)
)
SELECT 
    f.title,
    f.production_year,
    f.actor_name,
    f.total_votes,
    CASE 
        WHEN f.total_votes IS NULL THEN 'No Votes'
        ELSE 'Has Votes'
    END AS vote_status
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.total_votes DESC
LIMIT 10;
