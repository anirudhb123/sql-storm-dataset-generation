WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        c.kind AS role_type,
        COUNT(p.id) AS total_movies
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name, a.id, c.kind
),

KeywordDetails AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.role_type,
    SUM(kd.keyword_count) AS total_keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordDetails kd ON md.movie_id = kd.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.actor_name, md.role_type
ORDER BY 
    md.production_year DESC, total_keywords DESC;
This SQL query benchmarks string processing by summarizing movie details from the `aka_title`, `cast_info`, and `aka_name` tables while also aggregating keyword counts from the `movie_keyword` and `keyword` tables. The output includes the movie ID, title, production year, actor name, role type, and total keywords, sorted by production year and keyword count for advanced analysis.
