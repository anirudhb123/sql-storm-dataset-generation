WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        rt.title,
        rt.actor_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5  -- Get top 5 movies per year
), 
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)

SELECT 
    tm.title,
    tm.actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    info.info AS additional_info,
    CASE 
        WHEN i.info IS NOT NULL THEN 'Has Info'
        ELSE 'No Info'
    END AS info_status
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.title = (SELECT title FROM aka_title WHERE id = mi.movie_id LIMIT 1)
LEFT JOIN 
    movie_info info ON mi.movie_id = info.movie_id AND info.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
ORDER BY 
    tm.actor_count DESC, tm.title ASC;

-- Additional insights: 
-- 1. This query fetches the top 5 movies per year based on actor count while also ensuring a comprehensive record of their keywords and additional info.
-- 2. It uses window functions for ranking, COALESCE for NULL logic, and subqueries for correlation.
-- 3. The use of STRING_AGG and conditionals ensures clear representation of whether additional info exists.
