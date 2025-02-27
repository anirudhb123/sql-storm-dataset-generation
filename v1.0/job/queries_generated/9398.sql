WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        ak.name AS actor_name,
        k.keyword
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords
FROM 
    MovieDetails md
GROUP BY 
    md.title, md.production_year
ORDER BY 
    md.production_year DESC;
