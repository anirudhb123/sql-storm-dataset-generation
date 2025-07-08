
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        cast_info c ON c.movie_id = m.id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.id, m.title, m.production_year
),
HighCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        actor_names,
        keywords,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.total_cast,
    h.actor_names,
    h.keywords
FROM 
    HighCastMovies h
WHERE 
    h.rank <= 10
ORDER BY 
    h.total_cast DESC;
