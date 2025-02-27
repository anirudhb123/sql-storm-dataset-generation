WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),
TopRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    tr.title,
    tr.production_year,
    tr.cast_count,
    tr.keyword_count,
    array_agg(DISTINCT ak.name) AS aka_names
FROM 
    TopRankedMovies tr
LEFT JOIN 
    aka_title ak ON tr.movie_id = ak.movie_id
GROUP BY 
    tr.movie_id, tr.title, tr.production_year, tr.cast_count, tr.keyword_count
ORDER BY 
    tr.production_year DESC, tr.cast_count DESC;
