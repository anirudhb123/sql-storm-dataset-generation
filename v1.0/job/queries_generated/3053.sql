WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.id AS movie_id, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank 
    FROM title t
    WHERE t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year 
    FROM RankedMovies rm 
    WHERE rm.year_rank <= 5
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name, 
        r.role AS role_name, 
        COUNT(ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY a.name, r.role
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
FullMovieInfo AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        ak.actor_name, 
        ak.role_name, 
        mk.keywords
    FROM TopMovies tm
    LEFT JOIN ActorRoles ak ON ak.movie_count > 0
    LEFT JOIN MovieKeywords mk ON mk.movie_id IN (
        SELECT DISTINCT ci.movie_id 
        FROM cast_info ci 
        WHERE ci.movie_id IN (
            SELECT movie_id 
            FROM complete_cast cc 
            WHERE cc.status_id IS NULL
        )
    )
)
SELECT 
    fmi.title, 
    fmi.production_year, 
    fmi.actor_name, 
    fmi.role_name, 
    COALESCE(fmi.keywords, 'No Keywords') AS keywords 
FROM FullMovieInfo fmi
ORDER BY fmi.production_year DESC, fmi.title;
