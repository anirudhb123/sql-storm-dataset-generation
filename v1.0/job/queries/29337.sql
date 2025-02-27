WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)

SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    rt.role AS role,
    ci.note AS cast_note,
    mt.info AS movie_summary
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rt ON ci.person_role_id = rt.id
LEFT JOIN 
    movie_info mt ON tm.movie_id = mt.movie_id AND mt.info_type_id = (
        SELECT id FROM info_type WHERE info = 'summary'
    )
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC;
