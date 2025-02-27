WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopYearlyMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    m.title,
    m.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cast_count, 0) AS cast_count,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_indicator,
    T1.total_movies AS total_movies_in_production_year,
    T2.total_cast_in_year AS total_cast_in_year
FROM 
    TopYearlyMovies m
LEFT JOIN 
    MovieKeywords mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    (SELECT 
         production_year,
         COUNT(*) AS total_movies
     FROM 
         aka_title
     GROUP BY 
         production_year) AS T1 ON m.production_year = T1.production_year
LEFT JOIN 
    (SELECT 
         c.production_year,
         SUM(cast_count) AS total_cast_in_year
     FROM 
         (SELECT 
              t.production_year,
              COUNT(c.person_id) AS cast_count
          FROM 
              aka_title t
          LEFT JOIN 
              cast_info c ON t.id = c.movie_id
          GROUP BY 
              t.id, t.production_year) AS c
     GROUP BY 
         c.production_year) AS T2 ON m.production_year = T2.production_year
WHERE 
    era_indicator IS NOT NULL
ORDER BY 
    m.production_year DESC, 
    cast_count DESC;
