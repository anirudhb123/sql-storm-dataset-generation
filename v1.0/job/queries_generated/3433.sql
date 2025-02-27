WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieActors AS (
    SELECT 
        DISTINCT t.movie_id,
        m.title,
        STRING_AGG(DISTINCT a.actor_name, ', ') AS actors
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        t.movie_id, m.title
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.actor_name,
    tm.movie_title,
    tm.production_year,
    ca.actors,
    GROUP_CONCAT(DISTINCT cm.company_name || ' (' || cm.company_type || ')') AS company_details
FROM 
    TopMovies tm
LEFT JOIN 
    MovieActors ca ON tm.movie_title = ca.title
LEFT JOIN 
    CompanyMovies cm ON tm.movie_id = cm.movie_id
WHERE 
    tm.production_year BETWEEN 2000 AND 2023
GROUP BY 
    tm.actor_name, tm.movie_title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.actor_name;
