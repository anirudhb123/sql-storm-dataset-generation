WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT m.name, ', ') AS production_companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name m ON m.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
ranked_actors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_acted_in,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON t.id = ci.movie_id
    WHERE 
        ci.nr_order = 1  -- primary role
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    ra.name AS lead_actor,
    ra.movies_acted_in,
    ra.movies,
    rm.keywords
FROM 
    ranked_movies rm
JOIN 
    ranked_actors ra ON ra.movies_acted_in = rm.cast_count
WHERE 
    rm.cast_count >= 3  -- Movies with at least 3 actors
ORDER BY 
    rm.production_year DESC, 
    ra.movies_acted_in DESC;
