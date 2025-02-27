WITH movie_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
movie_with_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT p.name) AS cast_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        m.id
),
final_benchmark AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.keywords,
        mwc.cast_names,
        mwk.title || ' | Keywords: ' || COALESCE(mwk.keywords, 'None') || ' | Cast: ' || COALESCE(mwc.cast_names::text, 'None') AS benchmark_string
    FROM 
        movie_with_keywords mwk
    LEFT JOIN 
        movie_with_cast mwc ON mwk.movie_id = mwc.movie_id
)
SELECT 
    *,
    LENGTH(benchmark_string) AS string_length
FROM 
    final_benchmark
WHERE 
    string_length > 100
ORDER BY 
    string_length DESC
LIMIT 50;
