WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT a.name ORDER BY a.name) AS aka_names,
        COUNT(DISTINCT c.person_id) AS num_cast_members
    FROM title m
    JOIN aka_title a ON m.id = a.movie_id
    LEFT JOIN cast_info c ON m.id = c.movie_id
    WHERE m.production_year BETWEEN 2000 AND 2020
    GROUP BY m.id
),
genre_counts AS (
    SELECT 
        m.movie_id,
        k.keyword AS genre,
        COUNT(mk.keyword_id) AS genre_count
    FROM ranked_movies m
    JOIN movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.movie_id, k.keyword
),
ranked_genres AS (
    SELECT 
        movie_id,
        genre,
        genre_count,
        RANK() OVER (PARTITION BY movie_id ORDER BY genre_count DESC) AS genre_rank
    FROM genre_counts
)

SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.aka_names,
    COUNT(DISTINCT rg.genre) AS unique_genre_count,
    MAX(rg.genre_rank) AS most_frequent_genre_rank
FROM ranked_movies rm
LEFT JOIN ranked_genres rg ON rm.movie_id = rg.movie_id
GROUP BY rm.movie_id, rm.movie_title, rm.production_year, rm.aka_names
ORDER BY rm.production_year DESC, unique_genre_count DESC;
