WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year, 
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
),
ActorMovieCount AS (
    SELECT 
        actor_name, 
        COUNT(*) AS movie_count
    FROM 
        RankedTitles
    GROUP BY 
        actor_name
    HAVING 
        COUNT(*) > 5
),
MostFrequentGenres AS (
    SELECT 
        m.movie_id,
        k.keyword AS genre,
        COUNT(*) AS genre_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id, k.keyword
),
TopGenres AS (
    SELECT 
        genre,
        SUM(genre_count) AS total_genre_count
    FROM 
        MostFrequentGenres
    GROUP BY 
        genre
    ORDER BY 
        total_genre_count DESC
    LIMIT 5
)
SELECT 
    at.actor_name,
    at.movie_title,
    at.production_year,
    AVG(AVG_COUNT.total_genre_count) AS average_genre_count
FROM 
    RankedTitles at
JOIN 
    ActorMovieCount ac ON at.actor_name = ac.actor_name
JOIN 
    MostFrequentGenres mg ON at.movie_title = mg.movie_id
JOIN 
    TopGenres tg ON mg.genre = tg.genre
GROUP BY 
    at.actor_name, at.movie_title, at.production_year
ORDER BY 
    average_genre_count DESC, at.production_year DESC;
