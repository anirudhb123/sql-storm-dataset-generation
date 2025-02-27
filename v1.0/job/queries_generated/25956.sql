WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.title, a.production_year, k.keyword
), 
HighCastMovies AS (
    SELECT 
        title,
        production_year,
        keyword,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY keyword ORDER BY cast_count DESC) AS rank
    FROM 
        RankedTitles
)
SELECT 
    hcm.title,
    hcm.production_year,
    hcm.keyword,
    hcm.cast_count
FROM 
    HighCastMovies hcm
WHERE 
    hcm.rank <= 5
ORDER BY 
    hcm.keyword, 
    hcm.cast_count DESC;

This query benchmarks string processing by analyzing movie titles associated with keywords and their cast counts, ranking them, and returning the top 5 movies per keyword based on the number of unique cast members.
