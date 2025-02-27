WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title m
    JOIN 
        movie_companies mc ON mc.movie_id = m.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        cast_info c ON c.movie_id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
detailed_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.rank,
        mk.keywords,
        (SELECT STRING_AGG(DISTINCT ak.name, ', ') 
         FROM aka_title ak 
         WHERE ak.movie_id = rm.movie_id) AS aka_names,
        (SELECT STRING_AGG(DISTINCT p.info, '; ') 
         FROM person_info p 
         JOIN cast_info ci ON ci.person_id = p.person_id 
         WHERE ci.movie_id = rm.movie_id) AS person_info
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keywords mk ON mk.movie_id = rm.movie_id
    WHERE 
        rm.rank <= 5  -- Limiting to top 5 movies per year
)
SELECT 
    dm.movie_id,
    dm.title,
    dm.production_year,
    dm.kind_id,
    dm.rank,
    dm.keywords,
    COALESCE(dm.aka_names, 'No Alternate Names') AS aka_names,
    COALESCE(dm.person_info, 'No Associated Person Info') AS person_info
FROM 
    detailed_movies dm
ORDER BY 
    dm.production_year DESC, 
    dm.rank;
