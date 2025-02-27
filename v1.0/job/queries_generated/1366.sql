WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        MAX(CASE WHEN ci.person_role_id IS NOT NULL THEN a.name END) AS main_actor,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
avg_movie_rating AS (
    SELECT 
        m.movie_id,
        AVG(r.rating) AS average_rating
    FROM 
        movie_info m
    LEFT JOIN 
        (SELECT movie_id, rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) r 
    ON 
        m.movie_id = r.movie_id
    GROUP BY 
        m.movie_id
),
final_output AS (
    SELECT 
        md.title,
        md.production_year,
        md.main_actor,
        md.keywords,
        COALESCE(amr.average_rating, 0) AS average_rating
    FROM 
        movie_details md
    LEFT JOIN 
        avg_movie_rating amr ON md.title = (SELECT title FROM title WHERE id = (SELECT movie_id FROM aka_title WHERE id = md.id))
    WHERE 
        md.production_year > 2000
        AND (md.keywords IS NOT NULL OR md.main_actor IS NOT NULL)
)
SELECT 
    title,
    production_year,
    main_actor,
    keywords,
    average_rating
FROM 
    final_output
ORDER BY 
    average_rating DESC, 
    production_year ASC
LIMIT 10;
