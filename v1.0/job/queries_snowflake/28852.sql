
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS production_company_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS cast_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        production_company_count, 
        cast_names, 
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.production_company_count,
    tm.cast_names,
    tm.keywords,
    COUNT(DISTINCT m.id) AS related_movies_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_link ml ON tm.movie_id = ml.movie_id
LEFT JOIN 
    aka_title m ON ml.linked_movie_id = m.id
GROUP BY 
    tm.title, tm.production_year, tm.production_company_count, tm.cast_names, tm.keywords
ORDER BY 
    tm.production_year DESC, 
    tm.production_company_count DESC;
