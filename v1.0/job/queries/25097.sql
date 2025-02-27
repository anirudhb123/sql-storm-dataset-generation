WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actor_names,
        keywords,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
)
SELECT 
    tm.title,
    tm.actor_count,
    tm.production_year,
    tm.actor_names,
    tm.keywords
FROM 
    TopMovies AS tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC;
