WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(a.name) AS actors,
        COUNT(DISTINCT kc.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT kc.keyword_id) DESC) AS rank_with_keywords
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword kc ON m.id = kc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
SelectedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actors,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_with_keywords <= 5
)
SELECT 
    sm.movie_id,
    sm.title,
    sm.production_year,
    string_agg(sm.actors::text, ', ') AS actor_list,
    sm.keyword_count
FROM 
    SelectedMovies sm
JOIN 
    movie_info mi ON sm.movie_id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
GROUP BY 
    sm.movie_id, sm.title, sm.production_year, sm.keyword_count
ORDER BY 
    sm.production_year DESC, sm.keyword_count DESC;

This elaborate query does the following:
1. It establishes a CTE (`RankedMovies`) to gather movie data along with a ranking based on the count of associated keywords for each movie within its production year.
2. It selects the top 5 movies per their production year and their corresponding actors and keyword counts in another CTE (`SelectedMovies`).
3. Finally, it gathers information about these selected movies, joining it with the `movie_info` to filter further for specific info types and aggregates the actor names into a comma-separated list.
4. The results are sorted by production year and keyword count.
