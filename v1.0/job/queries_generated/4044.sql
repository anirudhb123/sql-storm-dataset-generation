WITH MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        a.name AS actor_name,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
TopMovies AS (
    SELECT
        md.title, 
        md.production_year, 
        md.actor_name, 
        md.production_companies
    FROM 
        MovieDetails md
    WHERE 
        md.rn = 1
    ORDER BY 
        md.production_year DESC
    LIMIT 10
),
ActorInfo AS (
    SELECT 
        a.name,
        pi.info AS biography,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name, pi.info
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.actor_name,
    ai.biography, 
    ai.movie_count
FROM 
    TopMovies tm
LEFT JOIN 
    ActorInfo ai ON tm.actor_name = ai.name
WHERE 
    ai.movie_count > 5 OR ai.biography IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.actor_name;
