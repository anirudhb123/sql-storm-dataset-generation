WITH MovieDetails AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        c.role_id,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_order,
        COALESCE(n.gender, 'Unknown') AS gender,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        name n ON a.person_id = n.imdb_id
    LEFT JOIN 
        movie_keyword k ON t.movie_id = k.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        a.id, a.name, t.title, t.production_year, c.role_id, n.gender
),
PopularMovies AS (
    SELECT 
        movie_title,
        production_year,
        AVG(role_order) AS avg_role_order
    FROM 
        MovieDetails
    WHERE 
        keyword_count > 5
    GROUP BY 
        movie_title, production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        RANK() OVER (ORDER BY avg_role_order ASC) AS rank
    FROM 
        PopularMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(tm.rank, 'Not Ranked') AS movie_rank,
    COALESCE(md.aka_name, 'Unnamed') AS actor_name,
    COUNT(DISTINCT md.aka_id) AS distinct_actor_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieDetails md ON tm.movie_title = md.movie_title AND tm.production_year = md.production_year
GROUP BY 
    tm.movie_title, tm.production_year, tm.rank, md.aka_name
ORDER BY 
    tm.production_year DESC, tm.movie_rank;
