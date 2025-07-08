
WITH movie_summary AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(c.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COALESCE(MAX(mi.info), 'No additional info') AS additional_info
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info AS mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
year_grouped AS (
    SELECT 
        production_year,
        COUNT(movie_id) AS movies_count,
        SUM(total_cast) AS total_cast_count,
        LISTAGG(title, ', ') WITHIN GROUP (ORDER BY title) AS movie_titles
    FROM 
        movie_summary
    GROUP BY 
        production_year
)

SELECT 
    g.production_year,
    g.movies_count,
    g.total_cast_count,
    g.movie_titles,
    ROW_NUMBER() OVER (ORDER BY g.production_year DESC) AS rank
FROM 
    year_grouped AS g
ORDER BY 
    g.production_year DESC;
