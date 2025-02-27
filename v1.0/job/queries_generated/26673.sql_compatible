
WITH RecursiveMovieInfo AS (
    SELECT 
        a.title, 
        a.production_year, 
        p.name AS actor_name, 
        STRING_AGG(kw.keyword, ',') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY p.name) AS actor_order
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        complete_cast cc ON cc.movie_id = a.id
    JOIN 
        aka_name p ON p.person_id = cc.subject_id
    GROUP BY 
        a.id, a.title, a.production_year, p.name
),
KeywordCount AS (
    SELECT 
        title, 
        production_year, 
        COUNT(DISTINCT keywords) AS unique_keyword_count
    FROM 
        RecursiveMovieInfo
    GROUP BY 
        title, 
        production_year
),
ActorCount AS (
    SELECT 
        title, 
        production_year, 
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        RecursiveMovieInfo
    GROUP BY 
        title, 
        production_year
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(k.unique_keyword_count, 0) AS unique_keyword_count,
    COALESCE(a.actor_count, 0) AS actor_count
FROM 
    aka_title m
LEFT JOIN 
    KeywordCount k ON m.title = k.title AND m.production_year = k.production_year
LEFT JOIN 
    ActorCount a ON m.title = a.title AND m.production_year = a.production_year
WHERE 
    m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    m.production_year DESC, 
    m.title;
