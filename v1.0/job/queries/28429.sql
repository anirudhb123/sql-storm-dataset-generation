WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count, 
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie'))
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        aka_names
    FROM 
        RankedMovies
    WHERE 
        rn <= 5  
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    COALESCE(CAST(count(DISTINCT mc.company_id) AS INTEGER), 0) AS company_count,
    COALESCE((
        SELECT STRING_AGG(DISTINCT cn.name, ', ') 
        FROM movie_companies AS mc
        JOIN company_name AS cn ON mc.company_id = cn.id
        WHERE mc.movie_id = tm.movie_id
    ), 'No companies') AS production_companies,
    COALESCE((
        SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
        FROM movie_keyword AS mk
        JOIN keyword AS k ON mk.keyword_id = k.id
        WHERE mk.movie_id = tm.movie_id
    ), 'No keywords') AS associated_keywords
FROM 
    TopMovies AS tm
LEFT JOIN 
    movie_companies AS mc ON tm.movie_id = mc.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.aka_names
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;