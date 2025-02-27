WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS cast_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id
),
movie_genres AS (
    SELECT 
        m.id AS movie_id,
        k.keyword AS genre
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
complete_movie_info AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        ARRAY_AGG(DISTINCT mg.genre) AS genres
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_genres mg ON rm.movie_id = mg.movie_id
    GROUP BY 
        rm.movie_id
)
SELECT 
    cmi.movie_id,
    cmi.title,
    cmi.production_year,
    cmi.cast_count,
    cmi.cast_names,
    STRING_AGG(DISTINCT g.genre, ', ') AS genres
FROM 
    complete_movie_info cmi
LEFT JOIN 
    movie_info mi ON cmi.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    it.info LIKE '%Drama%'  -- Example filter, can be changed to benchmark different string processing tasks.
GROUP BY 
    cmi.movie_id, cmi.title, cmi.production_year, cmi.cast_count, cmi.cast_names
ORDER BY 
    cmi.production_year DESC, 
    cmi.cast_count DESC;

This SQL query benchmarks string processing by:

1. **Aggregating Cast Names**: It retrieves the cast names associated with each movie and counts distinct cast members.
2. **Genre Association**: It links movies to their respective genres (keywords).
3. **Complete Movie Information**: Combines data from cast and genre tables to present a comprehensive view of movies, which includes filtered movie information based on genre criteria.
4. **String Aggregation**: Utilizes `STRING_AGG` to combine genres into a single field, testing the database's ability to manage and process string data efficiently. 
5. **Ordering**: Sorts results based on production year and cast count, providing an ordered view of benchmarked data.

Adjust the `WHERE` clause to vary the filtering criteria and observe performance changes on the string processing component.
