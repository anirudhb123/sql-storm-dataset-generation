
WITH MovieRoleCounts AS (
    SELECT 
        t.title AS movie_title,
        ci.role_id,
        r.role AS role_name,
        COUNT(ci.id) AS actor_count
    FROM 
        title t 
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        t.title, ci.role_id, r.role
),
FrequentRoles AS (
    SELECT 
        movie_title,
        role_name,
        actor_count
    FROM 
        MovieRoleCounts
    WHERE 
        actor_count > 3
),
HighDramaMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(k.id) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword = 'drama'
    GROUP BY 
        t.title, t.production_year
    HAVING 
        COUNT(k.id) > 5
),
FinalOutput AS (
    SELECT 
        hdm.title AS drama_movie,
        hdm.production_year,
        fr.role_name,
        fr.actor_count
    FROM 
        HighDramaMovies hdm
    JOIN 
        FrequentRoles fr ON hdm.title = fr.movie_title
)
SELECT 
    COUNT(*) AS total_drama_roles
FROM 
    FinalOutput;
