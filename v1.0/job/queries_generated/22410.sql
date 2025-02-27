WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        role_type r ON r.id = c.role_id
    WHERE 
        c.note IS NULL
    GROUP BY 
        c.movie_id, a.name, r.role
),
HighProfileActors AS (
    SELECT 
        actor_name,
        SUM(role_count) AS total_roles
    FROM 
        ActorRoles
    GROUP BY 
        actor_name
    HAVING 
        SUM(role_count) > 5
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON c.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY 
        m.movie_id, c.name, ct.kind
)
SELECT 
    rm.movie_title,
    rm.production_year,
    ah.actor_name,
    ah.total_roles,
    COALESCE(mc.company_name, 'Independent') AS production_company,
    COALESCE(mc.company_type, 'N/A') AS type,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    HighProfileActors ah ON rm.title_id IN (SELECT movie_id FROM ActorRoles WHERE actor_name = ah.actor_name)
LEFT JOIN 
    MovieCompanies mc ON mc.movie_id = rm.title_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = rm.title_id
WHERE 
    rm.year_rank <= 10 
    AND rm.production_year IS NOT NULL
    AND (ah.actor_name IS NOT NULL OR mc.company_name IS NULL)
GROUP BY 
    rm.movie_title, rm.production_year, ah.actor_name, ah.total_roles, mc.company_name, mc.company_type
ORDER BY 
    rm.production_year DESC, keyword_count DESC;

### Explanation of the Query:
- The query starts by creating several Common Table Expressions (CTEs) to structure the data and simplify further queries.
- **RankedMovies** selects movie titles along with their production years and assigns a rank based on the production year.
- **ActorRoles** aggregates the role counts of actors across different movies, filtering out any roles with notes.
- **HighProfileActors** filters for actors who have played more than five roles.
- **MovieCompanies** gathers data on the production companies involved in the movies, which includes counts of how many times each company has produced a movie.
- The final SELECT clause combines all this data, left joining the CTEs to ensure that all movies are included, even if they have no associated actors or production companies.
- The output is filtered for the top 10 most recent movies and ensures there’s a NULL logic check, plus counting unique keywords associated with the movies.
