WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword_count,
        cast_count,
        RANK() OVER (ORDER BY keyword_count DESC, cast_count DESC) AS ranking
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.cast_count,
    p.name AS director_name,
    co.name AS production_company
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON mi.info_type_id = (SELECT id FROM info_type WHERE info = 'director')
LEFT JOIN 
    name p ON pi.person_id = p.imdb_id
WHERE 
    tm.ranking <= 10;
