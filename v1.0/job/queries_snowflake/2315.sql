
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
rich_cast_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        ranked_movies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        rm.rank <= 5 AND rm.production_year IS NOT NULL
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
movies_with_keywords AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        k.keyword
    FROM 
        rich_cast_movies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.cast_count, 0) AS total_cast,
    COALESCE(m.actor_names, 'No actors') AS actors,
    COALESCE(LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword), 'No keywords') AS keywords
FROM 
    rich_cast_movies m
LEFT JOIN 
    movies_with_keywords k ON m.movie_id = k.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year, m.cast_count, m.actor_names
ORDER BY 
    m.production_year DESC, total_cast DESC;
