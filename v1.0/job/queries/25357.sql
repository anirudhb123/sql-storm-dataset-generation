WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
FilteredMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_by_cast
    FROM 
        RankedMovies
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.kind_id,
    fm.cast_count,
    fm.actors,
    fm.keywords
FROM 
    FilteredMovies fm
WHERE 
    fm.rank_by_cast <= 5  
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;