WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
TopActors AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.title_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    t.title,
    t.production_year,
    ta.name AS top_actor,
    COALESCE(mkw.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies t
LEFT JOIN 
    TopActors ta ON ta.movie_count > 0
INNER JOIN 
    MoviesWithKeywords mkw ON mkw.movie_id = t.title_id
WHERE 
    t.rn <= 3
ORDER BY 
    t.production_year DESC, 
    ta.name;
