WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.total_cast,
        r.actor_names,
        COALESCE(pk.keywords, 'No keywords') AS keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        PopularKeywords pk ON r.movie_id = pk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.actor_names,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.total_cast > 5
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
