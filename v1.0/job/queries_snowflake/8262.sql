
WITH RankedMovies AS (
    SELECT 
        a.id AS aka_name_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        COUNT(ci.id) AS total_cast,
        LISTAGG(DISTINCT p.name, ', ') WITHIN GROUP (ORDER BY p.name) AS cast_names
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        name p ON ci.person_id = p.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name, t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        aka_name_id,
        aka_name,
        title_id,
        title,
        production_year,
        total_cast,
        cast_names,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.aka_name_id,
    tm.aka_name,
    tm.title_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
