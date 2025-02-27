WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mw ON a.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    WHERE 
        a.production_year >= 2000 
    GROUP BY 
        a.id
), RankedMovies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
    FROM 
        MovieDetails md
)
SELECT 
    R.movie_title, 
    R.production_year, 
    R.cast_count, 
    R.actors,
    COALESCE(NULLIF(R.keyword_count, 0), 'No Keywords') AS keyword_info
FROM 
    RankedMovies R
WHERE 
    R.rank_within_year <= 5
ORDER BY 
    R.production_year DESC, 
    R.cast_count DESC;
