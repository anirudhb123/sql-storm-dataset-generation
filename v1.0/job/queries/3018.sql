WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_movies,
        MAX(production_year) AS last_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        total_movies,
        last_year,
        RANK() OVER (ORDER BY total_movies DESC) AS rank
    FROM 
        ActorStats
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        CASE 
            WHEN mi.info IS NULL THEN 'No Info'
            ELSE mi.info
        END AS info,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        m.id, m.title, mi.info
)
SELECT 
    ta.actor_name,
    ta.total_movies,
    ta.last_year,
    md.movie_id,
    md.title,
    md.info,
    md.companies
FROM 
    TopActors ta
JOIN 
    cast_info ci ON ta.actor_name = (SELECT a.name FROM aka_name a WHERE a.person_id = ci.person_id LIMIT 1)
JOIN 
    MovieDetails md ON ci.movie_id = md.movie_id
WHERE 
    ta.rank <= 10
ORDER BY 
    ta.total_movies DESC, md.title;
