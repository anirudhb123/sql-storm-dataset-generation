WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rnk
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        COALESCE(rn.rnk, 0) AS rank,
        m.actor_count,
        m.roles,
        COALESCE(k.keyword, 'No Keywords') AS associated_keyword
    FROM 
        ActorRoles m
    LEFT JOIN 
        RankedMovies rn ON m.movie_id = rn.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    d.rank,
    d.title,
    d.production_year,
    d.actor_count,
    d.roles,
    d.associated_keyword
FROM 
    MovieDetails d
WHERE 
    d.rank > 0 AND 
    (d.actor_count > 5 OR d.associated_keyword IS NOT NULL) 
ORDER BY 
    d.production_year DESC, d.rank ASC;
