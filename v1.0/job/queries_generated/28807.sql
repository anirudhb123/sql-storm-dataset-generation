WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index,
        c.note AS role_note
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000 
        AND ak.name ILIKE '%Smith%'
),

movie_keywords AS (
    SELECT 
        kw.keyword,
        mk.movie_id
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
),

detailed_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_details md
    LEFT JOIN 
        movie_keywords mk ON md.movie_title = (SELECT title FROM title WHERE imdb_index = md.movie_title LIMIT 1)
    GROUP BY 
        md.movie_title, md.production_year
)

SELECT 
    dm.movie_title,
    dm.production_year,
    dm.keywords,
    COUNT(*) AS actor_count
FROM 
    detailed_movies dm
JOIN 
    aka_name ak ON ak.name IN (SELECT unnest(string_to_array(dm.keywords, ', ')))
GROUP BY 
    dm.movie_title, dm.production_year
ORDER BY 
    dm.production_year DESC, actor_count DESC
LIMIT 10;
