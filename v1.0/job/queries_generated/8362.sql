WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS principal_actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        rm.*,
        RANK() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    tr.movie_id,
    tr.title,
    tr.production_year,
    tr.cast_count,
    tr.principal_actors,
    tr.keywords
FROM 
    TopRankedMovies tr
WHERE 
    tr.rank <= 10
ORDER BY 
    tr.cast_count DESC, 
    tr.production_year DESC;
