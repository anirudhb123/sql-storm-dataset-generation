WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS average_cast_roles
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        keyword_count,
        average_cast_roles,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC, average_cast_roles DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(n.name, 'Unknown Actor') AS actor_name,
    tm.keyword_count,
    tm.average_cast_roles
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name n ON cc.subject_id = n.person_id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
