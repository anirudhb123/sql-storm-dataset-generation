
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        t.production_year DESC
), 
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.actor_count,
        m.actor_names,
        m.keywords,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.actor_count DESC) AS rank
    FROM 
        RankedMovies m
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.actor_names,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.rank <= 5
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
