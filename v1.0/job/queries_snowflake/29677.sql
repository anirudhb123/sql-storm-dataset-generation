
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ka.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ca.nr_order) AS rank
    FROM 
        aka_title m
    JOIN 
        cast_info ca ON ca.movie_id = m.id
    JOIN 
        aka_name ka ON ka.person_id = ca.person_id
    WHERE 
        m.production_year >= 2000
),
ActorCounts AS (
    SELECT 
        actor_name,
        COUNT(movie_id) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 3
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name
    FROM 
        ActorCounts
    WHERE 
        movie_count > 5
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        m.id IN (
            SELECT DISTINCT movie_id 
            FROM cast_info 
            WHERE person_id IN (
                SELECT ka.id 
                FROM aka_name ka 
                WHERE ka.name IN (
                    SELECT actor_name 
                    FROM TopActors
                )
            )
        )
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    title, 
    production_year, 
    keywords
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, 
    title;
