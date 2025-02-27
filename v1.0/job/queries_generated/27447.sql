WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        num_cast,
        cast_names,
        RANK() OVER (ORDER BY num_cast DESC) AS movie_rank
    FROM 
        RankedMovies
    WHERE 
        num_cast > 5
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.num_cast,
    tm.cast_names,
    info.info AS additional_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    it.info LIKE '%Award%'
GROUP BY 
    tm.movie_id, info.info
ORDER BY 
    tm.movie_rank, tm.production_year DESC;
