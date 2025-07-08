
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aliases,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year, cast_count, aliases
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    m.aliases,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    TopMovies m
LEFT JOIN 
    (SELECT 
         mk.movie_id, 
         LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords 
     FROM 
         movie_keyword mk 
     JOIN 
         keyword k ON mk.keyword_id = k.id 
     GROUP BY 
         mk.movie_id) mk ON m.movie_id = mk.movie_id
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
