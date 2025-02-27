WITH movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order,
        COALESCE(a.name_pcode_nf, 'UNKNOWN') AS name_pcode_nf,
        COALESCE(a.md5sum, 'NO_MD5SUM') AS actor_md5sum
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
movie_keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword_info mk ON mt.id = mk.movie_id
),
ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (ORDER BY keyword_count DESC, title) AS keyword_rank
    FROM 
        movie_details md
    WHERE 
        production_year IS NOT NULL AND 
        title NOT LIKE '%untitled%' 
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.keyword_count,
    mc.actor_name,
    mc.actor_order,
    mc.actor_md5sum
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_cast mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.keyword_rank <= 10 AND
    (rm.keywords IS NOT NULL OR mc.actor_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.keyword_count DESC, 
    mc.actor_order ASC;