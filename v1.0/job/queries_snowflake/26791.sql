
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aliases,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rnk
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        aliases,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rnk = 1
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.aliases,
    tm.keywords
FROM 
    TopMovies tm
ORDER BY 
    tm.actor_count DESC, 
    tm.production_year DESC
LIMIT 10;
