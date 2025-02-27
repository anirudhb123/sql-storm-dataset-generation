WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        k.keyword AS main_keyword
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
    ORDER BY 
        cast_count DESC
    LIMIT 10
)

SELECT 
    rm.title, 
    rm.production_year, 
    rm.cast_count, 
    rm.cast_names, 
    COALESCE(k.keyword, 'No Keyword') AS keyword_info,
    rt.role AS role_description,
    COUNT(DISTINCT ci.person_id) AS role_count
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = rm.title AND production_year = rm.production_year)
JOIN 
    role_type rt ON rt.id = ci.role_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = (SELECT id FROM aka_title WHERE title = rm.title AND production_year = rm.production_year)
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
GROUP BY 
    rm.title, rm.production_year, rm.cast_count, rm.cast_names, keyword_info, rt.role
ORDER BY 
    rm.production_year DESC, role_count DESC;

This SQL query benchmarks string processing by aggregating data from various tables using `JOINs` and `STRING_AGG`. It retrieves the top 10 movies produced after the year 2000, counting the number of unique cast members, and lists their names alongside the main keyword associated with the movie. It further analyzes the roles played in these top movies and counts how many cast members played each role, also including movie ratings when present.
