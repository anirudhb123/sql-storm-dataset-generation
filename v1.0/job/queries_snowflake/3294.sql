WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
TopActors AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
    HAVING 
        COUNT(ci.person_id) > 1
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(CAST(mt.kind AS TEXT), 'Unknown') AS movie_type,
        COALESCE(k.keyword, 'No Keyword') AS movie_keyword
    FROM 
        title m
    LEFT JOIN 
        kind_type mt ON m.kind_id = mt.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rm.aka_id,
    rm.title,
    rm.production_year,
    ta.actor_name,
    md.movie_type,
    md.movie_keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON rm.aka_id = ta.movie_id
JOIN 
    MovieDetails md ON rm.title = md.title AND rm.production_year = md.production_year
WHERE 
    md.movie_keyword IS NOT NULL
ORDER BY 
    rm.production_year DESC, ta.role_count DESC NULLS LAST
LIMIT 100;
