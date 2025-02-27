
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.movie_id, r.role) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyMovies AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        ct.kind = 'Production'
),
ActorsInMovies AS (
    SELECT 
        cm.movie_id,
        STRING_AGG(DISTINCT a.actor_name, ', ') AS actors_list
    FROM 
        ActorRoles a
    JOIN 
        CompanyMovies cm ON a.movie_id = cm.movie_id
    GROUP BY 
        cm.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(aim.actors_list, 'No Actors') AS actors,
    CASE 
        WHEN rm.rank_title <= 5 THEN 'Top 5 Title'
        ELSE 'Other Titles'
    END AS title_rank,
    AVG(ar.role_count) AS average_role_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsInMovies aim ON rm.movie_id = aim.movie_id
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, aim.actors_list, rm.rank_title
ORDER BY 
    rm.production_year DESC, title_rank, rm.title;
