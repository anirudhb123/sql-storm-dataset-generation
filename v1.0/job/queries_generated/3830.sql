WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast = 1
),
ActorsWithKeywords AS (
    SELECT 
        a.name,
        k.keyword
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(a.keyword, 'No Keyword') AS keyword,
    a.name AS actor_name
FROM 
    TopMovies tm
LEFT JOIN 
    ActorsWithKeywords a ON tm.title = a.keyword
ORDER BY 
    tm.production_year DESC, 
    tm.title;
