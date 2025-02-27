
WITH movie_data AS (
    SELECT 
        mt.title,
        mt.production_year,
        kc.kind AS movie_kind,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COALESCE(SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END), 0) AS has_info,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS cast_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        kind_type kc ON mt.kind_id = kc.id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
    GROUP BY 
        mt.id, mt.title, mt.production_year, kc.kind
),

yearly_statistics AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count,
        AVG(total_cast) AS avg_cast_per_movie,
        SUM(has_info) AS movies_with_info
    FROM 
        movie_data
    GROUP BY 
        production_year
)

SELECT 
    ys.production_year,
    ys.movie_count,
    ys.avg_cast_per_movie,
    ys.movies_with_info,
    STRING_AGG(m.title, '; ') AS movies_with_most_cast_names
FROM 
    yearly_statistics ys
JOIN 
    movie_data m ON ys.production_year = m.production_year
WHERE 
    ys.movie_count > 5
    AND (ys.avg_cast_per_movie > (SELECT AVG(avg_cast_per_movie) FROM yearly_statistics) OR ys.movies_with_info > 0)
GROUP BY 
    ys.production_year, ys.movie_count, ys.avg_cast_per_movie, ys.movies_with_info
HAVING 
    COUNT(m.title) > 3
ORDER BY 
    ys.production_year DESC, ys.movie_count DESC;
