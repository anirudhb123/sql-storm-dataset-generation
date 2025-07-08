
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 5
),
MovieStats AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(mi.info, 'N/A') AS movie_info,
        COALESCE(LISTAGG(DISTINCT cn.name, ', '), 'No Cast') AS cast_names
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_info mi ON t.title = mi.info
    LEFT JOIN 
        cast_info ci ON t.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    GROUP BY 
        t.title, t.production_year, mi.info
)
SELECT 
    mv.title,
    mv.production_year,
    mv.movie_info,
    mv.cast_names,
    CASE 
        WHEN mv.production_year < 2000 THEN 'Classic'
        WHEN mv.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(DISTINCT kc.keyword) AS keyword_count
FROM 
    MovieStats mv
LEFT JOIN 
    movie_keyword mk ON mv.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
GROUP BY 
    mv.title, mv.production_year, mv.movie_info, mv.cast_names, mv.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 2
ORDER BY 
    mv.production_year DESC, mv.title ASC;
