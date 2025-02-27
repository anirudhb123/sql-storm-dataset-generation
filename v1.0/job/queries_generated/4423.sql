WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id, 
        title,
        production_year
    FROM RankedMovies
    WHERE movie_rank <= 5
),
ActorNames AS (
    SELECT 
        a.name AS actor_name,
        ARRAY_AGG(DISTINCT t.title) AS movie_titles
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    GROUP BY a.name
),
MovieKeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN title m ON mk.movie_id = m.id
    GROUP BY m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    an.actor_name,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN mkc.keyword_count > 10 THEN 'High'
        WHEN mkc.keyword_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low' 
    END AS keyword_density,
    STRING_AGG(DISTINCT an.movie_titles::text, ', ') AS titles_with_actor
FROM TopMovies tm
LEFT JOIN ActorNames an ON tm.title = ANY(an.movie_titles)
LEFT JOIN MovieKeywordCounts mkc ON tm.title_id = mkc.movie_id
GROUP BY tm.title, tm.production_year, an.actor_name, mkc.keyword_count
ORDER BY tm.production_year DESC, keyword_density DESC;
