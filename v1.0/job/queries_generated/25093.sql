WITH movie_data AS (
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year, 
        mt.kind_id, 
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT kp.keyword) AS keywords,
        ARRAY_AGG(DISTINCT cmp.name) AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    LEFT JOIN 
        keyword kp ON kp.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = mt.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mcp ON mcp.movie_id = mt.id
    LEFT JOIN 
        company_name cmp ON cmp.id = mcp.company_id
    WHERE 
        mt.production_year > 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id
),
aggregate_statistics AS (
    SELECT 
        kind_id,
        COUNT(movie_id) AS total_movies,
        AVG(cast_count) AS avg_cast_size,
        ARRAY_AGG(DISTINCT title ORDER BY production_year) AS movie_titles,
        MAX(production_year) AS last_production_year
    FROM 
        movie_data
    GROUP BY 
        kind_id
)
SELECT 
    kt.kind, 
    as.total_movies, 
    as.avg_cast_size, 
    as.movie_titles, 
    as.last_production_year
FROM 
    aggregate_statistics as
JOIN 
    kind_type kt ON kt.id = as.kind_id
ORDER BY 
    as.total_movies DESC;
