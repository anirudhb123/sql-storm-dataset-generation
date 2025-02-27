WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
),
MovieDetails AS (
    SELECT 
        t.title, 
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COALESCE(mi.info, 'No Info') AS additional_info
    FROM 
        TopMovies t
    LEFT JOIN 
        cast_info ci ON t.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON (SELECT movie_id FROM movie_info WHERE id = ci.movie_id)
    GROUP BY 
        t.title, mi.info
)
SELECT 
    md.title,
    md.actors,
    md.additional_info
FROM 
    MovieDetails md
WHERE 
    md.title LIKE '%The%' 
    OR md.additional_info IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.title;
