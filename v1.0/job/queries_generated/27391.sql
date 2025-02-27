WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        AVG(CASE WHEN ci.role_id = rt.id THEN ci.nr_order ELSE NULL END) AS avg_role_order
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year,
        keyword_count,
        avg_role_order,
        RANK() OVER (ORDER BY keyword_count DESC, avg_role_order DESC) AS movie_rank
    FROM 
        RankedMovies
    WHERE 
        keyword_count > 0
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.keyword_count,
    tm.avg_role_order,
    COUNT(DISTINCT c.person_id) AS total_cast_members,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    COUNT(DISTINCT mc.company_id) AS total_companies
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
WHERE 
    tm.movie_rank <= 10
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, tm.keyword_count, tm.avg_role_order
ORDER BY 
    tm.movie_rank;
