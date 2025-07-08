
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS movie_keywords
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
TopRankedMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        cast_count,
        actor_names,
        movie_keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tr.movie_title,
    tr.production_year,
    tr.cast_count,
    tr.actor_names,
    tr.movie_keywords
FROM 
    TopRankedMovies AS tr
WHERE 
    tr.rank <= 10
ORDER BY 
    tr.rank;
