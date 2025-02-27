WITH ranked_movies AS (
    SELECT 
        m.title AS movie_title,
        m.production_year,
        t.kind AS movie_kind,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS movie_keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title m
    JOIN 
        aka_title ak_t ON m.id = ak_t.movie_id
    JOIN 
        aka_name ak ON ak_t.id = ak.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        kind_type t ON m.kind_id = t.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year, t.kind
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
popular_movies AS (
    SELECT 
        movie_title,
        production_year,
        movie_kind,
        aka_names,
        movie_keywords,
        cast_count,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS movie_rank
    FROM 
        ranked_movies
)
SELECT 
    movie_title,
    production_year,
    movie_kind,
    aka_names,
    movie_keywords,
    cast_count
FROM 
    popular_movies
WHERE 
    movie_rank <= 10
ORDER BY 
    production_year DESC, cast_count DESC;
