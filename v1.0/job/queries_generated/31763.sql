WITH RECURSIVE ActorMovies AS (
    SELECT 
        c.person_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) as movie_rank
    FROM 
        cast_info c
    JOIN 
        title t ON c.movie_id = t.id
),
RecentMovies AS (
    SELECT
        person_id,
        COUNT(*) as total_movies,
        MAX(production_year) as last_movie_year
    FROM 
        ActorMovies
    WHERE
        movie_rank <= 5  -- Limit to the last 5 movies for each actor
    GROUP BY 
        person_id
),
PersonDetails AS (
    SELECT 
        a.person_id,
        a.name,
        r.role,
        COALESCE(r.note, 'No role specified') as role_note
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
MovieCompanies AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        title m ON mc.movie_id = m.id
    GROUP BY 
        m.id
)

SELECT 
    pd.name AS actor_name,
    rm.total_movies,
    rm.last_movie_year,
    STRING_AGG(dm.title || ' (' || dm.production_year || ')', ', ') AS recent_titles,
    mc.companies AS production_companies
FROM 
    RecentMovies rm
JOIN 
    PersonDetails pd ON rm.person_id = pd.person_id
JOIN 
    ActorMovies dm ON pd.person_id = dm.person_id
JOIN 
    MovieCompanies mc ON dm.movie_id = mc.movie_id
WHERE 
    rm.last_movie_year >= 2020 -- Filtering for actors who acted in movies since 2020
GROUP BY 
    pd.name, rm.total_movies, rm.last_movie_year, mc.companies
ORDER BY 
    rm.total_movies DESC, rm.last_movie_year DESC;
