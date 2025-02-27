WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title AS mt
    LEFT JOIN 
        cast_info AS ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
genre_movies AS (
    SELECT 
        mt.movie_id,
        kt.kind AS genre
    FROM 
        movie_info AS mi
    JOIN 
        info_type AS it ON mi.info_type_id = it.id
    JOIN 
        kind_type AS kt ON it.info LIKE '%' || kt.kind || '%'
    WHERE 
        kt.kind IS NOT NULL
),
final_benchmark AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names,
        rm.keywords,
        STRING_AGG(DISTINCT gm.genre, ', ') AS genres
    FROM 
        ranked_movies AS rm
    LEFT JOIN 
        genre_movies AS gm ON rm.movie_id = gm.movie_id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rm.cast_count, rm.aka_names
)

SELECT 
    fb.movie_id,
    fb.movie_title,
    fb.production_year,
    fb.cast_count,
    fb.aka_names,
    fb.keywords,
    fb.genres
FROM 
    final_benchmark AS fb
ORDER BY 
    fb.production_year DESC, 
    fb.cast_count DESC;
