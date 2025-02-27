WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
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
        rn <= 5
),
ActorsWithRoles AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        rt.role AS role_name,
        COALESCE(MAX(m.info), 'No info available') AS info
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Tagline' LIMIT 1)
    WHERE 
        t.id IN (SELECT id FROM aka_title WHERE kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%'))
    GROUP BY 
        ak.name, t.title, rt.role
)
SELECT 
    a.actor_name,
    a.movie_title,
    a.role_name,
    COALESCE(STRING_AGG(DISTINCT a.info, '; '), 'No additional info') AS additional_info,
    COALESCE(b.production_year, 'Unknown') AS production_year
FROM 
    ActorsWithRoles a
FULL OUTER JOIN 
    TopMovies b ON a.movie_title = b.title
GROUP BY 
    a.actor_name, a.movie_title, a.role_name, b.production_year
ORDER BY 
    COUNT(DISTINCT a.role_name) DESC, b.production_year DESC;
