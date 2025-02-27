WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(CAST(SUM(CASE WHEN c.person_role_id = r.id THEN 1 ELSE 0 END) AS INTEGER), 0) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_year
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        RANK() OVER (ORDER BY total_cast DESC) AS movie_rank
    FROM 
        RankedMovies
    WHERE 
        total_cast > 0
)

SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    mk.keyword,
    cn.name AS company_name,
    p.info AS person_info
FROM 
    TopMovies tm
JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    person_info p ON mc.movie_id = p.person_id
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.total_cast DESC, tm.production_year ASC;

This SQL query creates a ranking of movies based on the total number of cast members, determines the top movies, and retrieves relevant information such as associated keywords, production companies, and person information for those movies.
