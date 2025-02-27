WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 3
),
MovieDetails AS (
    SELECT 
        m.movie_title,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        TopMovies m
    LEFT JOIN 
        cast_info c ON m.movie_title = (SELECT title FROM aka_title WHERE id = c.movie_id)
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = m.movie_title LIMIT 1)
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.movie_title, m.production_year
)
SELECT 
    md.movie_title,
    md.actor_names,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 0 THEN 'Has Keywords' 
        ELSE 'No Keywords' 
    END AS keyword_status
FROM 
    MovieDetails md
ORDER BY 
    md.keyword_count DESC, md.movie_title;
