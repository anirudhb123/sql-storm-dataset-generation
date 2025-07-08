
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword 
    FROM 
        title m
    JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    LISTAGG(mk.keyword, ', ') WITHIN GROUP (ORDER BY mk.keyword) AS keywords,
    COUNT(DISTINCT ca.person_id) AS unique_actor_count,
    LISTAGG(DISTINCT CONCAT(a.name, ' as ', rt.role), ', ') WITHIN GROUP (ORDER BY a.name) AS actors_roles
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    role_type rt ON ca.role_id = rt.id
LEFT JOIN 
    aka_name a ON ca.person_id = a.person_id
GROUP BY 
    tm.movie_title, tm.production_year
ORDER BY 
    tm.production_year DESC, unique_actor_count DESC;
