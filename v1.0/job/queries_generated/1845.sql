WITH RecursiveKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM 
        title t 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY kc.keyword_count DESC) AS keyword_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    RecursiveKeywordCount kc ON t.id = kc.movie_id
WHERE 
    (EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = t.id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
    ) OR t.production_year > 2000)
    AND (a.name IS NOT NULL AND a.name NOT LIKE '%[0-9]%')
ORDER BY 
    t.production_year, keyword_count DESC;
