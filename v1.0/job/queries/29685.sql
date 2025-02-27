
WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        a.name AS actor_name,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = m.id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        m.id, m.title, m.production_year, a.name, ct.kind
),
ranked_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actor_name,
        company_type,
        keywords,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.company_type,
    rm.keywords,
    rm.cast_count,
    rm.rank
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
