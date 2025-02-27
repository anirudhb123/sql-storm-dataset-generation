WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 3
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        aka_title AS m ON mk.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(mk.keywords, 'No keywords available') AS keywords,
    (SELECT COUNT(*) 
     FROM movie_info AS mi 
     WHERE mi.movie_id = t.id 
       AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Awards%')) AS award_count,
    CASE 
        WHEN COUNT(DISTINCT c.person_id) = 0 THEN 'No cast available'
        ELSE 'Has cast'
    END AS cast_status
FROM 
    TopMovies AS t
LEFT JOIN 
    movie_keyword AS mk ON t.title = mk.movie_id
LEFT JOIN 
    cast_info AS c ON t.title = (SELECT title FROM aka_title WHERE id = c.movie_id) 
GROUP BY 
    t.title, t.production_year, mk.keywords
ORDER BY 
    t.production_year DESC, award_count DESC;

