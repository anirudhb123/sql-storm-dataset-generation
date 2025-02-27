WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast = 1
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
    tm.title, 
    tm.production_year, 
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = tm.movie_id AND cc.status_id IS NOT NULL) AS complete_cast_count,
    ARRAY(SELECT DISTINCT ON (ci.person_id) 
          a.name 
          FROM cast_info ci 
          JOIN aka_name a ON ci.person_id = a.person_id 
          WHERE ci.movie_id = tm.movie_id AND a.name IS NOT NULL
          ORDER BY ci.nr_order) AS unique_cast_names
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
