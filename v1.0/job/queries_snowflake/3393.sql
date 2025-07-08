
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10 
        AND rm.production_year >= 2000
),
RelatedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS related_title,
        ml.linked_movie_id
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.total_cast,
        ARRAY_AGG(DISTINCT rm.related_title) AS related_movies
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        RelatedMovies rm ON fm.movie_id = rm.movie_id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year, fm.total_cast
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    COALESCE(md.related_movies, ARRAY_CONSTRUCT()) AS related_movies
FROM 
    MovieDetails md
WHERE 
    md.total_cast IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
