
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.keyword_count,
        CASE 
            WHEN rm.production_year < 2000 THEN 'Oldie'
            WHEN rm.production_year >= 2000 AND rm.production_year < 2015 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        ranked_movies rm
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.keyword_count,
    md.era,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords
FROM 
    movie_details md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.cast_count, md.keyword_count, md.era
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
