WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        COUNT(DISTINCT c.person_id) AS num_actors,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        director_name,
        num_actors,
        keywords,
        DENSE_RANK() OVER (ORDER BY num_actors DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND num_actors > 5
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.director_name,
    fm.num_actors,
    fm.keywords
FROM 
    FilteredMovies AS fm
WHERE 
    fm.rank <= 10
ORDER BY 
    fm.rank, fm.production_year DESC;