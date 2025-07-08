
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title AS m
    JOIN 
        cast_info AS c ON m.id = c.movie_id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),
HighProfileMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actor_count,
        actor_names,
        keywords,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
)
SELECT 
    h.movie_id,
    h.movie_title,
    h.production_year,
    h.actor_count,
    h.actor_names,
    h.keywords
FROM 
    HighProfileMovies AS h
WHERE 
    h.rank <= 10
ORDER BY 
    h.production_year DESC, h.actor_count DESC;
