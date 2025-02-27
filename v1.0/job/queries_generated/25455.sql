WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.title) AS rank
    FROM
        aka_title a
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = a.id
    LEFT JOIN
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN
        cast_info c ON c.movie_id = a.id
    WHERE
        a.production_year >= 2000
    GROUP BY
        a.id, a.title, a.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
ActorDetails AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON ci.person_id = p.person_id
    GROUP BY 
        p.id, p.name
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.movie_keyword,
    tm.actor_count,
    ad.actor_name,
    ad.movies_count
FROM 
    TopMovies tm
JOIN 
    ActorDetails ad ON tm.actor_count > ad.movies_count
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
