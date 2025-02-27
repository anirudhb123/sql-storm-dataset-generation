
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mw ON a.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        actors,
        keywords,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    title,
    production_year,
    actor_count,
    actors,
    keywords
FROM 
    TopMovies
WHERE 
    rank <= 10;
