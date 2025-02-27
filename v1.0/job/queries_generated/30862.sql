WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id, 
        COUNT(*) AS role_count,
        STRING_AGG(DISTINCT at.title, ', ') AS movies_played
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT
        ah.person_id,
        ah.role_count,
        ah.movies_played,
        RANK() OVER (ORDER BY ah.role_count DESC) AS rank
    FROM 
        ActorHierarchy ah
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    ta.person_id,
    an.name,
    ta.role_count AS total_roles,
    ta.movies_played,
    cd.company_name,
    cd.company_type,
    cd.num_movies
FROM 
    TopActors ta
LEFT JOIN 
    aka_name an ON ta.person_id = an.person_id
LEFT JOIN 
    cast_info ci ON ta.person_id = ci.person_id
LEFT JOIN 
    CompanyDetails cd ON ci.movie_id = cd.movie_id
WHERE 
    ta.rank <= 10
ORDER BY 
    ta.role_count DESC, 
    cd.num_movies DESC NULLS LAST,
    an.name ASC;

### Explanation:
- The query starts with a CTE (`ActorHierarchy`) that recursively collects actors and their movie counts, aggregating the titles they've been involved in.
- A second CTE (`TopActors`) ranks these actors based on the number of roles, allowing us to focus on the top performers.
- Another CTE (`CompanyDetails`) gathers information about the companies involved in movie productions along with a count of movies for each company.
- Finally, the main query selects relevant information from these CTEs, joining with `aka_name` and `cast_info` to enrich the dataset. It filters out to only show the top 10 actors and orders the results by the number of roles, companies, and then names.
- The outer joins ensure that if an actor did not work with a company, the actor's information will still display, filling company fields with NULLs where appropriate.
- The usage of window functions enhances the ranking dynamics while aggregate functions like `COUNT` and `STRING_AGG` provide unique insights into the actors' contributions.
