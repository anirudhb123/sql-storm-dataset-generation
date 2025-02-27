WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        COUNT(DISTINCT c.person_role_id) AS total_roles,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_role_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_names,
        total_roles
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 5
    ORDER BY 
        production_year, total_roles DESC
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_names,
    tm.total_roles,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT ckt.kind, ', ') AS company_types
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ckt ON mc.company_type_id = ckt.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.actor_names, tm.total_roles
ORDER BY 
    tm.production_year DESC, tm.total_roles DESC;
