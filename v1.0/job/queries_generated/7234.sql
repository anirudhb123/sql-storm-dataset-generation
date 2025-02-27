WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
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
)
SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    ci.note AS role_note,
    ckt.kind AS cast_type
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    comp_cast_type ckt ON ci.person_role_id = ckt.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC, tm.title;
