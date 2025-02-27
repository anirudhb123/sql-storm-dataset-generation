WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.cast_count
    FROM 
        RankedMovies r
    WHERE 
        r.year_rank <= 5
),
MovieDetails AS (
    SELECT 
        f.title,
        f.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        (SELECT COUNT(DISTINCT mk.keyword_id) FROM movie_keyword mk WHERE mk.movie_id = f.id) AS keyword_count
    FROM 
        FilteredMovies f
    JOIN 
        movie_info mi ON f.id = mi.movie_id
    JOIN 
        movie_keyword mk ON f.id = mk.movie_id
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        f.title, f.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actors, 'No cast available') AS actors,
    md.keyword_count
FROM 
    MovieDetails md
WHERE 
    md.keyword_count > 0
ORDER BY 
    md.production_year DESC, md.title;
