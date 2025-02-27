
WITH movie_rankings AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.title, mt.production_year
), 

keyword_summary AS (
    SELECT 
        mt.title AS movie_title,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.title
),

movie_details AS (
    SELECT
        mr.movie_title,
        mr.production_year,
        mr.cast_count,
        mr.cast_names,
        ks.keyword_count,
        ks.keywords
    FROM
        movie_rankings mr
    JOIN
        keyword_summary ks ON mr.movie_title = ks.movie_title
)

SELECT 
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    md.keyword_count,
    md.keywords
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.cast_count DESC, 
    md.keyword_count DESC;
