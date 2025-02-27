WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
TopActors AS (
    SELECT 
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(ci.movie_id) > 5
), 
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.id
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ta.name, 'Unknown Actor') AS top_actor,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON ta.movie_count = (
        SELECT MAX(movie_count) 
        FROM TopActors
    )
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
