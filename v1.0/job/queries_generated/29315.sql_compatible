
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
SubqueryPersonRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.person_role_id = r.id
    GROUP BY 
        ci.movie_id, a.name, r.role
), 
FinalJoin AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keywords,
        rm.cast_count,
        spr.actor_name,
        spr.role_name,
        spr.role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        SubqueryPersonRoles spr ON rm.movie_id = spr.movie_id
)
SELECT 
    *,
    CONCAT('Movie: ', title, ' (', production_year, ') - Actor: ', actor_name, ' as ', role_name) AS display_info
FROM 
    FinalJoin
WHERE 
    cast_count > 5 AND 
    (ARRAY_LENGTH(keywords, 1) > 0)
ORDER BY 
    production_year DESC, 
    title;
