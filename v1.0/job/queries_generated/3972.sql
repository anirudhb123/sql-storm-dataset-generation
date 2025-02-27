WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieWithInfo AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No Info') AS movie_info,
        COUNT(mc.id) AS company_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.title = mi.info
    LEFT JOIN 
        movie_companies mc ON m.title = (SELECT title FROM aka_title WHERE movie_id = mc.movie_id LIMIT 1)
    WHERE 
        m.rank <= 10
    GROUP BY 
        m.title, m.production_year, mi.info
),
ActorMovies AS (
    SELECT 
        ak.name AS actor_name,
        a.title,
        COUNT(DISTINCT c.movie_id) AS total_movies
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info c ON ak.person_id = c.person_id
    INNER JOIN 
        aka_title a ON c.movie_id = a.movie_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name, a.title
),
FinalResults AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.movie_info,
        mw.company_count,
        am.actor_name,
        am.total_movies
    FROM 
        MovieWithInfo mw
    LEFT JOIN 
        ActorMovies am ON mw.title = am.title
)
SELECT 
    fr.title,
    fr.production_year,
    fr.movie_info,
    fr.company_count,
    fr.actor_name,
    fr.total_movies,
    CASE 
        WHEN fr.total_movies IS NULL THEN 'No Actors'
        ELSE fr.actor_name
    END AS display_actor_name
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, 
    fr.company_count DESC
LIMIT 20;
