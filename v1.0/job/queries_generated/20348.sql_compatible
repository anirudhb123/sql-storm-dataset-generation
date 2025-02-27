
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRatedActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(c.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(c.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(c.movie_id) > 5
    AND 
        MIN(c.nr_order) < 3 
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.title AS movie_title,
    r.production_year,
    a.name AS actor_name,
    a.movie_count,
    k.keyword_count,
    k.keywords,
    COALESCE(p.info, 'No Info') AS actor_info
FROM 
    RankedMovies r
LEFT JOIN 
    TopRatedActors a ON r.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = a.person_id)
LEFT JOIN 
    KeywordStats k ON r.movie_id = k.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography' LIMIT 1)
WHERE 
    r.rank_within_year <= 10
    AND r.production_year >= 2000 
    AND (a.actor_rank IS NULL OR a.actor_rank <= 10) 
ORDER BY 
    r.production_year DESC, 
    a.movie_count DESC,
    k.keyword_count DESC;
