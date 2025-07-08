
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
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
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ak.actor_name,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ak ON rm.movie_id = ak.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.year_rank <= 5
        AND rm.production_year BETWEEN 2000 AND 2023
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_name, 'No Actor') AS actor_name,
    COALESCE(tm.keywords, 'No Keywords') AS keywords
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.title;
