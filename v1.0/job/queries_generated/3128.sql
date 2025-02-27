WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
MovieRoles AS (
    SELECT 
        t.title,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.title, rt.role
),
PopularActors AS (
    SELECT 
        an.name,
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name an
    JOIN 
        cast_info ci ON an.person_id = ci.person_id
    GROUP BY 
        an.name
    HAVING 
        COUNT(ci.movie_id) > 10
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mr.role, 'No Role') AS movie_role,
    COALESCE(mr.role_count, 0) AS role_count,
    COALESCE(pa.name, 'Unknown Actor') AS popular_actor,
    COALESCE(pa.movies_count, 0) AS actor_movies_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieRoles mr ON rm.title = mr.title
LEFT JOIN 
    PopularActors pa ON pa.name = ANY(string_to_array(rm.title, ' '))
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
