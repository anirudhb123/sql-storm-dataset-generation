
WITH RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        actor_name, 
        movie_title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        movie_rank = 1
),
ModalKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk 
    GROUP BY 
        mk.movie_id
    HAVING 
        COUNT(DISTINCT mk.keyword_id) > 5
)
SELECT 
    fa.actor_name,
    fa.movie_title,
    fa.production_year,
    COALESCE(mk.keyword_count, 0) AS high_keyword_count
FROM 
    FilteredActors fa
LEFT JOIN 
    ModalKeywords mk ON fa.movie_title = (SELECT title FROM aka_title WHERE movie_id = mk.movie_id LIMIT 1)
    AND mk.movie_id IN (SELECT movie_id FROM aka_title WHERE title = fa.movie_title)
ORDER BY 
    fa.production_year DESC, fa.actor_name;
