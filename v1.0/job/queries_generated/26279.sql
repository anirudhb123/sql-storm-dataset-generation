WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS known_akas,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS movie_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.title, a.production_year
),

TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        cast_count, 
        known_akas, 
        keywords 
    FROM 
        RankedMovies 
    WHERE 
        movie_rank <= 10
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.known_akas,
    tm.keywords,
    COALESCE(cn.name, 'Unknown') AS company_name,
    GROUP_CONCAT(DISTINCT ct.kind) AS company_types
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    tm.movie_title, tm.production_year, tm.cast_count, tm.known_akas, tm.keywords, cn.name
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
