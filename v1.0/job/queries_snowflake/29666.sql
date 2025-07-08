
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        total_cast_members
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
ActorStatistics AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movies_participated,
        LISTAGG(DISTINCT tm.title, ', ') WITHIN GROUP (ORDER BY tm.title) AS movies_titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        TopMovies tm ON c.movie_id = tm.movie_id
    GROUP BY 
        a.name
)

SELECT 
    ts.actor_name,
    ts.movies_participated,
    ts.movies_titles
FROM 
    ActorStatistics ts
ORDER BY 
    ts.movies_participated DESC;
