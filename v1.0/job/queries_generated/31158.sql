WITH RECURSIVE ActorMovieCTE AS (
    SELECT c.person_id, c.movie_id, t.title, 1 AS level
    FROM cast_info c
    JOIN title t ON c.movie_id = t.id
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT c.person_id, c.movie_id, t.title, am.level + 1
    FROM cast_info c
    JOIN title t ON c.movie_id = t.id
    JOIN ActorMovieCTE am ON c.person_id = am.person_id
    WHERE t.production_year < 2000 AND am.level < 3
),
TopActors AS (
    SELECT a.person_id, COUNT(DISTINCT a.movie_id) AS movie_count
    FROM ActorMovieCTE a
    GROUP BY a.person_id
    ORDER BY movie_count DESC
    LIMIT 10
),
IndustryStats AS (
    SELECT
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        AVG(t.production_year) AS avg_production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM cast_info c
    JOIN title t ON c.movie_id = t.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
    GROUP BY c.person_id
)
SELECT
    a.id AS Actor_ID,
    na.name AS Actor_Name,
    COALESCE(s.total_movies, 0) AS Total_Movies,
    COALESCE(s.avg_production_year, NULL) AS Avg_Production_Year,
    COALESCE(s.keywords, 'No Keywords') AS Keywords,
    COUNT(DISTINCT am.movie_id) AS Frequent_Movies_Count
FROM aka_name na
JOIN TopActors ta ON na.person_id = ta.person_id
LEFT JOIN IndustryStats s ON s.person_id = na.person_id
LEFT JOIN ActorMovieCTE am ON na.person_id = am.person_id
WHERE na.name IS NOT NULL AND na.name <> ''
GROUP BY a.id, na.name, s.total_movies, s.avg_production_year, s.keywords
ORDER BY Frequent_Movies_Count DESC, Total_Movies DESC;
