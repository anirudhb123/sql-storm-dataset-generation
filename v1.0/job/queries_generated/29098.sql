WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
movie_info_aggregated AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mv.info, '; ') AS movie_info
    FROM 
        movie_info mv
    JOIN 
        ranked_movies m ON mv.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
final_output AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        k.kind AS movie_kind,
        rm.cast_count,
        rm.cast_names,
        mia.movie_info
    FROM 
        ranked_movies rm
    JOIN 
        kind_type k ON rm.kind_id = k.id
    JOIN 
        movie_info_aggregated mia ON rm.id = mia.movie_id
    WHERE 
        rm.rn = 1
    ORDER BY 
        rm.production_year DESC, rm.cast_count DESC
)
SELECT 
    movie_title,
    production_year,
    movie_kind,
    cast_count,
    cast_names,
    movie_info
FROM 
    final_output
LIMIT 50;
