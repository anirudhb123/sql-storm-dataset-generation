WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(actor_name, ', ') AS actors
    FROM 
        RankedMovies
    GROUP BY 
        movie_id, title, production_year
    ORDER BY 
        production_year DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        m.actors,
        COALESCE(k.keywords, 'No keywords') AS keywords,
        COALESCE(info.info_text, 'No additional info') AS additional_info
    FROM 
        TopMovies m
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) k ON m.movie_id = k.movie_id
    LEFT JOIN (
        SELECT 
            mi.movie_id,
            STRING_AGG(mi.info, '; ') AS info_text
        FROM 
            movie_info mi
        GROUP BY 
            mi.movie_id
    ) info ON m.movie_id = info.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    md.keywords,
    md.additional_info
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC;
