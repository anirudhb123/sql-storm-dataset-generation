WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT k.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT k.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
PersonMovieRoles AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        r.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
),
CombinedResults AS (
    SELECT 
        pm.actor_name,
        pm.movie_title,
        pm.role_name,
        tm.production_year,
        COALESCE(pm.role_name, 'Unknown') AS role_display
    FROM 
        PersonMovieRoles pm
    FULL OUTER JOIN 
        TopMovies tm ON pm.movie_title = tm.title
)
SELECT 
    actor_name,
    movie_title,
    role_display,
    production_year,
    CASE 
        WHEN production_year IS NULL THEN 'Year Unknown' 
        ELSE production_year::text 
    END AS production_year_display
FROM 
    CombinedResults
WHERE 
    (role_name IS NOT NULL OR role_display = 'Unknown')
ORDER BY 
    production_year DESC, actor_name;
