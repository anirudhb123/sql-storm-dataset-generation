
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year IS NOT NULL
        AND m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
), MovieRanked AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actors,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.actor_count,
    r.actors,
    r.keywords
FROM 
    MovieRanked r
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year DESC, 
    r.actor_count DESC;
