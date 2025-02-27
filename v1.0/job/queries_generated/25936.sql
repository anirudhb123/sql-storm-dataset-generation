WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.title) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),
TopKeywords AS (
    SELECT 
        keyword,
        COUNT(*) AS keyword_count
    FROM 
        RankedTitles
    GROUP BY 
        keyword
    HAVING 
        COUNT(*) > 5
),
ActorsInTopMovies AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        at.title IN (SELECT title FROM RankedTitles WHERE year_rank <= 10)
)
SELECT 
    actor_name,
    STRING_AGG(DISTINCT movie_title || ' (' || production_year || ')', ', ') AS movies,
    tk.keyword,
    tk.keyword_count
FROM 
    ActorsInTopMovies a
JOIN 
    TopKeywords tk ON a.movie_title LIKE '%' || tk.keyword || '%'
GROUP BY 
    actor_name, tk.keyword, tk.keyword_count
ORDER BY 
    actor_name, tk.keyword_count DESC;
