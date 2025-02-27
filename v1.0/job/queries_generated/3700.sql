WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
),
KeywordMovies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        km.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordMovies km ON rm.title = (SELECT t.title FROM aka_title t WHERE t.id = rm.title LIMIT 1)
    WHERE 
        rm.actor_count > 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    COALESCE(fm.keywords, 'No keywords available') AS keywords,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = (SELECT t.id FROM aka_title t WHERE t.title = fm.title LIMIT 1)) AS info_count
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year > 2000 
ORDER BY 
    fm.production_year DESC, 
    fm.actor_count DESC;
