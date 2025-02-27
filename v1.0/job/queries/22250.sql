WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS movie_rank,
        tk.keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature', 'short')) 
        AND (t.production_year IS NOT NULL OR t.production_year > 2000)
),

ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role,
        COUNT(ci.movie_id) AS movie_count,
        SUM(CASE WHEN t.production_year BETWEEN 2010 AND 2020 THEN 1 ELSE 0 END) AS decade_movies
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        ak.name, ct.kind
    HAVING 
        COUNT(ci.movie_id) > 5
)

SELECT 
    rm.production_year,
    STRING_AGG(DISTINCT rm.title, ', ') AS movie_titles,
    STRING_AGG(DISTINCT ar.actor_name || ' (' || ar.role || ' - ' || ar.movie_count || ' movies)', '; ') AS actors_with_roles,
    CASE 
        WHEN COUNT(DISTINCT ar.actor_name) > 10 THEN 'Many Actors'
        ELSE 'Few Actors'
    END AS actor_density
FROM 
    RankedMovies rm
FULL OUTER JOIN 
    ActorRoles ar ON rm.keyword = ar.role
WHERE 
    rm.movie_rank BETWEEN 1 AND 10
GROUP BY 
    rm.production_year
ORDER BY 
    rm.production_year DESC NULLS LAST;


