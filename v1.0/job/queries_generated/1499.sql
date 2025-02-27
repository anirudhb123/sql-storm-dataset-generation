WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND t.title IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.actors,
        RANK() OVER (ORDER BY md.cast_count DESC) AS rank
    FROM 
        movie_details md
    WHERE 
        md.cast_count > 0
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;

-- Additionally joining information about the company associated with the top movies
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    top_movies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    tm.title, tm.production_year, tm.cast_count, tm.actors
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
