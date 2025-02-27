WITH ranked_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.role_id) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY COUNT(c.role_id) DESC) AS rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        string_agg(DISTINCT r.actor_name, ', ') AS cast_list,
        COUNT(DISTINCT m.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword m ON t.id = m.movie_id
    LEFT JOIN 
        ranked_cast r ON t.id = r.movie_id AND r.rank <= 5
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
high_keyword_movies AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_list,
        md.keyword_count
    FROM 
        movie_details md
    WHERE 
        md.keyword_count > 3
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.cast_list, 'No cast available') AS cast_list,
    CASE 
        WHEN md.keyword_count IS NULL THEN 'No keywords'
        WHEN md.keyword_count > 5 THEN 'Richly Tagged'
        ELSE 'Moderately Tagged'
    END AS keyword_description
FROM 
    high_keyword_movies md
ORDER BY 
    md.production_year DESC, 
    md.title ASC;

-- Additionally, a bizarre twist where we find movies with matching keywords to their title.
WITH title_keyword_matches AS (
    SELECT 
        t.title,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.title ILIKE '%' || k.keyword || '%'
)
SELECT DISTINCT 
    tm.title,
    tm.keyword
FROM 
    title_keyword_matches tm
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%trivia%')
    )
ORDER BY 
    tm.title;
