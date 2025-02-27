WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.title_rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.title_rank = 1
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY r.role) AS role_rank
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
FinalOutput AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(ar.role, 'Unknown Role') AS lead_role,
        mg.genres,
        COALESCE(tlm.total_movies, 0) AS total_movies_in_year
    FROM 
        TopRankedMovies t
    LEFT JOIN 
        ActorRoles ar ON t.movie_id = ar.movie_id AND ar.role_rank = 1
    LEFT JOIN 
        MovieGenres mg ON t.movie_id = mg.movie_id
    LEFT JOIN 
        RankedMovies tlm ON t.production_year = tlm.production_year
)
SELECT 
    *,
    CASE 
        WHEN genres IS NULL THEN 'No Genres'
        ELSE genres 
    END AS final_genres
FROM 
    FinalOutput
WHERE 
    final_genres NOT LIKE '%Action%'
ORDER BY 
    production_year DESC, title;
