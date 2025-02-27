WITH movie_year AS (
    SELECT 
        title.id AS movie_id, 
        title.title, 
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.id, title.title, title.production_year
), 
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        total_cast,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank
    FROM 
        movie_year
),
movie_details AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.total_cast,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        COALESCE(ARRAY_AGG(DISTINCT mn.name) FILTER (WHERE mn.name IS NOT NULL), '{}') AS alternate_names
    FROM 
        top_movies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        name mn ON ak.person_id = mn.imdb_id
    WHERE 
        tm.rank <= 5
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.total_cast
),
keyword_info AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword ON mk.keyword_id = keyword.id
    GROUP BY 
        movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.actors,
    ki.keywords
FROM 
    movie_details md
LEFT JOIN 
    keyword_info ki ON md.movie_id = ki.movie_id
ORDER BY 
    md.production_year DESC, total_cast DESC
LIMIT 10;
