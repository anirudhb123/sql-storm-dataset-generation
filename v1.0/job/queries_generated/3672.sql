WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(m.id) OVER(PARTITION BY t.production_year) AS movie_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS total_actors
    FROM 
        cast_info c
    INNER JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MoviesWithRoles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ar.role, 'Unknown Role') AS role,
        ar.total_actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.role,
    mw.total_actors,
    COALESCE(CAST(SUM(mk.keyword) AS VARCHAR), 'No Keywords') AS keywords
FROM 
    MoviesWithRoles mw
LEFT JOIN 
    movie_keyword mk ON mw.movie_id = mk.movie_id
GROUP BY 
    mw.title, mw.production_year, mw.role, mw.total_actors
HAVING 
    mw.total_actors > 5 AND mw.production_year IS NOT NULL
ORDER BY 
    mw.production_year DESC, mw.title ASC;
