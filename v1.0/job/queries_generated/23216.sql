WITH RecursiveCTE AS (
    SELECT p.id AS person_id, a.name AS actor_name, COUNT(DISTINCT c.movie_id) AS movie_count,
           ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rn
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
    LEFT JOIN movie_info m ON t.movie_id = m.movie_id
    WHERE m.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Budget'
    ) AND m.info IS NOT NULL
    GROUP BY p.id, a.name
    HAVING COUNT(DISTINCT c.movie_id) > 5
), 
FilteredMovies AS (
    SELECT t.title, t.production_year, COUNT(DISTINCT c.person_id) AS actor_count
    FROM aka_title t
    JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    WHERE mc.note IS NULL
    GROUP BY t.title, t.production_year
    HAVING COUNT(DISTINCT c.person_id) > 10 AND COUNT(DISTINCT mc.company_id) > 1
), 
KeywordCounts AS (
    SELECT m.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
), 
TitleRatings AS (
    SELECT t.id AS title_id, t.title, 
           COALESCE(kw.keywords, 'No Keywords') AS keywords,
           ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kw.movie_id) DESC) AS rating
    FROM aka_title t
    LEFT JOIN KeywordCounts kw ON t.id = kw.movie_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, kw.keywords
)
SELECT DISTINCT f.title, f.production_year, t.keywords, 
    CASE 
        WHEN t.rating BETWEEN 1 AND 5 THEN 'Top Movie'
        WHEN t.rating BETWEEN 6 AND 10 THEN 'Popular'
        ELSE 'Less Known' 
    END AS rating_category
FROM FilteredMovies f
JOIN TitleRatings t ON f.title = t.title
ORDER BY f.production_year DESC, t.rating;
