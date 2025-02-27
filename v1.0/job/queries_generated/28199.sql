WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        kt.kind AS movie_kind,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        kind_type kt ON a.kind_id = kt.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, kt.kind
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        movie_kind,
        cast_count,
        actor_names
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
)
SELECT 
    mv.movie_id,
    mv.movie_title,
    mv.production_year,
    mv.movie_kind,
    mv.cast_count,
    mv.actor_names,
    GROUP_CONCAT(DISTINCT mc.note) AS company_notes
FROM 
    TopMovies mv
LEFT JOIN 
    movie_companies mc ON mv.movie_id = mc.movie_id
GROUP BY 
    mv.movie_id, mv.movie_title, mv.production_year, mv.movie_kind, mv.cast_count, mv.actor_names
ORDER BY 
    mv.production_year DESC, mv.cast_count DESC;
