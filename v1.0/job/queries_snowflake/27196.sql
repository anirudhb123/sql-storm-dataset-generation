
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year >= 2000
        AND cn.country_code = 'USA'
    GROUP BY 
        m.id, m.title, m.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
),

MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        TopMovies tm
    JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_names,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year = (SELECT MAX(production_year) FROM MovieDetails)
ORDER BY 
    md.movie_id;
