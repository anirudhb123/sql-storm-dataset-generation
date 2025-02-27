
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT ca.person_id) AS num_actors
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info AS ca ON t.id = ca.movie_id
    GROUP BY 
        t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.keywords,
        md.companies,
        md.num_actors
    FROM 
        MovieDetails md
    WHERE 
        md.production_year >= 2000 AND
        md.num_actors > 5
)
SELECT 
    f.movie_title,
    f.production_year,
    f.keywords,
    f.companies,
    f.num_actors
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.num_actors DESC
LIMIT 10;
