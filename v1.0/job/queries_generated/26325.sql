WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(CASE WHEN r.role = 'Actor' THEN 1 ELSE 0 END), 0) AS actor_count,
        COALESCE(SUM(CASE WHEN r.role = 'Director' THEN 1 ELSE 0 END), 0) AS director_count,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, m.title) AS rank
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.person_role_id = r.id
    GROUP BY 
        m.id
),

FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        director_count
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5 AND director_count > 1
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_count,
    f.director_count,
    ARRAY_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')')) AS cast_details
FROM 
    FilteredMovies f
JOIN 
    cast_info ci ON f.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.person_role_id = r.id
GROUP BY 
    f.movie_id, f.title, f.production_year, f.actor_count, f.director_count
ORDER BY 
    f.production_year DESC, f.title;

This query benchmarks string processing by:
1. Ranking movies based on their production year and title.
2. Filtering those with more than 5 actors and more than 1 director.
3. Joining with `aka_name` to aggregate details about the cast.
4. Constructing a final output that includes the movie details and an array of cast names with their respective roles.
