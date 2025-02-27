WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        k.keyword, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        keyword 
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieDetails AS (
    SELECT 
        t.title,
        COALESCE(c.name, 'Unknown') AS company_name,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT p.name, ', ') AS actors
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        t.title, c.name
)
SELECT 
    m.title, 
    m.production_year, 
    m.keyword, 
    m.company_name, 
    m.actor_count, 
    m.actors
FROM 
    TopMovies tm
JOIN 
    MovieDetails m ON tm.title = m.title
WHERE 
    m.actor_count > 0
ORDER BY 
    m.production_year DESC, 
    m.title ASC;
