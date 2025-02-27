WITH movie_scores AS (
    SELECT 
        t.id AS movie_id,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS director,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN mi.info_type_id = 2 THEN 1 ELSE 0 END) AS has_synopsis,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id
),
ranked_movies AS (
    SELECT 
        ms.movie_id,
        ms.director,
        ms.keyword_count,
        ms.cast_count,
        ms.has_synopsis,
        ms.company_count,
        RANK() OVER (ORDER BY ms.keyword_count DESC, ms.cast_count DESC, ms.company_count DESC) AS rank
    FROM 
        movie_scores ms
)
SELECT 
    r.movie_id,
    r.director,
    r.keyword_count,
    r.cast_count,
    r.has_synopsis,
    r.company_count,
    r.rank
FROM 
    ranked_movies r
WHERE 
    r.rank <= 10;

This SQL query benchmarks string processing by calculating a score for each movie based on various string-related metrics:

1. **Director's Name**: This uses `MAX` to get the name of the director.
2. **Keyword Count**: Counts the distinct keywords associated to the movie to assess how well it is tagged.
3. **Cast Count**: Counts the distinct individuals in the cast.
4. **Synopsis Presence**: A binary check (1 or 0) to determine if a synopsis exists.
5. **Company Count**: Counts the distinct companies involved in the movie.

Then, the query ranks these movies based on their keyword count, cast count, and company involvement, filtering to return the top 10 movies.
