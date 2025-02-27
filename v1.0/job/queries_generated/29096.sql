WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        COUNT(DISTINCT ca.person_id) AS num_cast_members,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ca ON a.id = ca.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        keyword,
        num_cast_members
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast = 1
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    n.name AS top_actor,
    COUNT(ci.role_id) AS role_count,
    STRING_AGG(DISTINCT ci.note, ', ') AS actor_notes
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.production_year = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_role_id
JOIN 
    aka_name n ON ci.person_id = n.person_id
GROUP BY 
    tm.title, tm.production_year, tm.keyword, n.name
ORDER BY 
    tm.production_year DESC, role_count DESC;
