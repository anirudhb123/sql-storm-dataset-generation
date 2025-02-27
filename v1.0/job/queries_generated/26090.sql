WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
MovieRanked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT
    mr.movie_id,
    mr.title,
    mr.production_year,
    mr.cast_count,
    mr.actor_names,
    mr.keywords
FROM 
    MovieRanked mr
WHERE 
    rank <= 5
ORDER BY 
    mr.production_year DESC, 
    mr.cast_count DESC;

This SQL query benchmarks string processing by aggregating and concatenating actor names and keywords associated with movies produced from the year 2000 onward. It ranks movies based on the count of distinct actors in descending order and selects the top 5 movies per production year.
