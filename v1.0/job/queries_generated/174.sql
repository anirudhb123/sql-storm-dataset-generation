WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
CastSummary AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count,
        STRING_AGG(movie_title, ', ') AS movies
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 5
    GROUP BY 
        actor_name
),
KeywordCount AS (
    SELECT 
        t.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
)
SELECT 
    cs.actor_name,
    cs.movie_count,
    cs.movies,
    kc.keyword_count
FROM 
    CastSummary cs
LEFT JOIN 
    KeywordCount kc ON kc.movie_id = (SELECT id FROM aka_title WHERE title = cs.movies LIMIT 1)
WHERE 
    cs.movie_count > 1 OR kc.keyword_count IS NULL
ORDER BY 
    cs.movie_count DESC, kc.keyword_count ASC;
