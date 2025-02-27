WITH RecursiveName AS (
    SELECT 
        n.id AS name_id,
        n.name AS name_text,
        n.imdb_index AS imdb_index,
        c.name AS character_name,
        t.title AS movie_title,
        t.production_year AS movie_year,
        a.name AS actor_name,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY n.id ORDER BY t.production_year DESC) AS rn
    FROM name n
    JOIN cast_info ci ON n.id = ci.person_id
    JOIN aka_name a ON a.person_id = ci.person_id
    JOIN title t ON t.id = ci.movie_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN char_name c ON c.imdb_index = n.imdb_index
    WHERE n.gender = 'F'
), NamedMovies AS (
    SELECT 
        rn.name_id,
        rn.name_text,
        rn.imdb_index,
        rn.movie_title,
        rn.movie_year,
        rn.actor_name,
        rn.keyword
    FROM RecursiveName rn
    WHERE rn.rn <= 5
    ORDER BY rn.movie_year DESC
)
SELECT 
    n.name_text,
    COUNT(DISTINCT n.movie_title) AS movie_count,
    STRING_AGG(DISTINCT n.keyword, ', ') AS keywords
FROM NamedMovies n
GROUP BY n.name_text
ORDER BY movie_count DESC
LIMIT 10;

This query generates a report on the top 10 female names, counting their distinct movie appearances and aggregating associated keywords. It utilizes common table expressions (CTEs) to streamline recursive selection and ensures a rich dataset for benchmarking string processing techniques.
