WITH movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        rn.rank AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        (SELECT 
            movie_id, 
            person_id, 
            ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY nr_order) AS rank
        FROM 
            cast_info) rn ON c.movie_id = rn.movie_id AND c.person_id = rn.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
filtered_movies AS (
    SELECT 
        t.production_year,
        t.title,
        COALESCE(mc.actor_name, 'Unknown Actor') AS leading_actor,
        mk.keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_cast mc ON t.id = mc.movie_id AND mc.actor_rank = 1
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= (SELECT AVG(production_year) FROM aka_title)
        OR mk.keywords ILIKE '%thriller%'
),
final_selection AS (
    SELECT 
        fm.production_year,
        fm.title,
        fm.leading_actor,
        fm.keywords,
        ROW_NUMBER() OVER (PARTITION BY fm.production_year ORDER BY fm.title) AS year_rank
    FROM 
        filtered_movies fm
)
SELECT 
    fs.production_year,
    fs.title,
    fs.leading_actor,
    COALESCE(NULLIF(fs.keywords, ''), 'No Keywords') AS keywords,
    CASE 
        WHEN fs.year_rank <= 10 THEN 'Top 10'
        ELSE 'Below Top 10'
    END AS rating_category
FROM 
    final_selection fs
WHERE 
    fs.leading_actor IS NOT NULL
ORDER BY 
    fs.production_year DESC, fs.title;
