WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', c.nr_order, ')'), ', ') AS full_cast,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year > 2000
        AND c.nr_order IS NOT NULL
    GROUP BY 
        m.id
),
filtered_movies AS (
    SELECT 
        rm.*,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, rm.cast_count DESC) AS rank
    FROM 
        ranked_movies rm
    WHERE 
        rm.cast_count > 5
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.full_cast,
    fm.keywords
FROM 
    filtered_movies fm
WHERE 
    fm.rank <= 10
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;

This query performs the following operations:
1. It retrieves movie titles, production years, and full cast information for movies produced after the year 2000.
2. The `ranked_movies` Common Table Expression (CTE) computes the number of distinct cast members per movie and aggregates cast names along with their order.
3. The `filtered_movies` CTE ranks these movies based on production year and casts count, filtering out those with fewer than 6 cast members.
4. Finally, it selects the top 10 ranked movies and displays their details in descending order of production year and cast count.
