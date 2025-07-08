
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_in_year
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.title, a.production_year, a.id
),

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count,
        actors,
        movie_id
    FROM 
        RankedMovies
    WHERE 
        rank_in_year <= 5
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    k.keyword AS movie_keyword,
    ct.kind AS company_type,
    mi.info AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
