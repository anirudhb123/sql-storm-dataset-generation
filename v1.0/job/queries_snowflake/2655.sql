
WITH RankedMovies AS (
    SELECT 
        a.title,
        ak.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year BETWEEN 1990 AND 2020
),
ActorMovieCount AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT title) AS movie_count
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorMovieCount
    WHERE 
        movie_count > 5
),
MovieGenres AS (
    SELECT 
        a.title,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS genres
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    mg.title,
    mg.genres
FROM 
    TopActors ta
LEFT JOIN 
    RankedMovies rm ON ta.actor_name = rm.actor_name
LEFT JOIN 
    MovieGenres mg ON rm.title = mg.title
WHERE 
    ta.rank <= 10
ORDER BY 
    ta.movie_count DESC, mg.title;
