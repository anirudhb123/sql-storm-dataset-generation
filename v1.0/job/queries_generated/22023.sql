WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(y.production_year) AS avg_year
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        title t ON m.id = t.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        kind_type kt ON m.kind_id = kt.id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year IS NOT NULL 
        AND m.production_year > 2000
        AND c.person_role_id IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
), 

ActorRoleCTE AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_number
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
), 

FilteredMovies AS (
    SELECT 
        rm.*,
        ar.actor_name,
        ar.role_name,
        ar.actor_number
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoleCTE ar ON rm.movie_id = ar.movie_id
    WHERE 
        rm.actor_count > 5 
        AND rm.production_year = (
            SELECT MAX(production_year)
            FROM RankedMovies
        )
)

SELECT 
    f.title,
    f.production_year,
    MAX(f.actor_count) AS total_actors,
    STRING_AGG(DISTINCT f.actor_name || ' (' || f.role_name || ')', ', ') AS actor_details
FROM 
    FilteredMovies f
GROUP BY 
    f.title, f.production_year
HAVING 
    MAX(f.actor_count) IS NOT NULL
    AND COUNT(f.actor_number) > 0
ORDER BY 
    f.production_year DESC, 
    total_actors DESC;
