WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(*) OVER(PARTITION BY t.production_year) AS year_count,
        COALESCE(mk.keyword, 'No Keywords') AS keyword_info
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, a.name, rt.role
),
MoviesWithRoleCounts AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role,
        ar.role_count,
        rm.year_rank,
        rm.year_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_name,
        role,
        year_rank,
        year_count,
        NULLIF(role_count, 0) AS non_zero_role_count
    FROM 
        MoviesWithRoleCounts
    WHERE 
        year_rank <= 5 
      AND 
        (role IS NOT NULL OR production_year < 2000)
)
SELECT 
    tm.production_year,
    COUNT(DISTINCT tm.title) AS total_movies,
    STRING_AGG(DISTINCT tm.actor_name, ', ') AS actors,
    SUM(COALESCE(tm.non_zero_role_count, 0)) AS total_non_zero_roles,
    COUNT(DISTINCT CASE WHEN tm.year_count > 1 THEN tm.title END) AS multi_movie_years,
    CASE 
        WHEN MAX(tm.production_year) - MIN(tm.production_year) > 10 
        THEN 'Spanning Over a Decade'
        ELSE 'Less than a Decade'
    END AS summary
FROM 
    TopMovies tm
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
