WITH ranked_movies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS rank
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.person_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year > 2000
),
movie_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(na.name, ', ') AS cast_names,
        STRING_AGG(na.name_pcode_cf, ', ') AS name_pcodes
    FROM 
        cast_info c
    JOIN 
        name na ON c.person_id = na.imdb_id
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.aka_id,
    rm.aka_name,
    rm.movie_title,
    rm.production_year,
    mc.cast_names,
    mc.name_pcodes,
    rm.keyword
FROM 
    ranked_movies rm
JOIN 
    movie_cast mc ON rm.aka_id = mc.movie_id
WHERE 
    rm.rank <= 3
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;

This query includes Common Table Expressions (CTEs) to first rank movies based on the names in the `aka_name` table while filtering for titles produced after the year 2000. It also aggregates the cast names for each movie using the `STRING_AGG` function. The final output selects relevant fields from both CTEs, only including the top three names for each title.
