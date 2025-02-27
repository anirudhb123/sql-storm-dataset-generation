WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(mi.info IS NOT NULL AND it.info = 'rating') OVER (PARTITION BY rm.movie_id), 0) AS rating_count,
        COALESCE(STRING_AGG(DISTINCT kw.keyword, ', ') OVER (PARTITION BY rm.movie_id), 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        rm.actor_count_rank <= 5
)
SELECT 
    d.movie_id, 
    d.title, 
    d.production_year,
    d.rating_count,
    d.keywords
FROM 
    MovieDetails d
WHERE 
    d.production_year >= 2000
ORDER BY 
    d.production_year DESC, d.rating_count DESC
LIMIT 10
UNION
SELECT 
    t.id AS movie_id, 
    t.title, 
    t.production_year, 
    0 AS rating_count,
    'No Keywords' AS keywords
FROM 
    aka_title t
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM MovieDetails md 
        WHERE md.movie_id = t.id
    )
    AND t.production_year < 2000
ORDER BY 
    t.production_year DESC
LIMIT 5;
