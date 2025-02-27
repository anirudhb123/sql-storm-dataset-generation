WITH movie_cast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        a.md5sum AS actor_md5,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
movie_info_with_keywords AS (
    SELECT
        mi.movie_id,
        mi.info AS movie_info,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        movie_info mi
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    GROUP BY 
        mi.movie_id, mi.info
),
extensive_movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(mc.actor_name, 'No Cast') AS main_actor,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS year_order
    FROM 
        title t
    LEFT JOIN 
        movie_cast mc ON t.id = mc.movie_id AND mc.actor_order = 1
    LEFT JOIN 
        movie_info_with_keywords k ON t.id = k.movie_id
),
final_benchmark AS (
    SELECT 
        emd.title_id,
        emd.title,
        emd.production_year,
        emd.main_actor,
        emd.keywords,
        (SELECT COUNT(*) FROM aka_title a_t WHERE a_t.production_year = emd.production_year) AS total_movies_of_year,
        NULLIF(emd.main_actor, 'No Cast') AS non_null_actor
    FROM 
        extensive_movie_details emd
    WHERE 
        emd.production_year IS NOT NULL 
        AND (emd.production_year > 1900 AND emd.production_year < 2025)
    ORDER BY 
        emd.production_year DESC, emd.title
)
SELECT 
    title_id,
    title,
    production_year,
    main_actor,
    keywords,
    total_movies_of_year,
    CASE 
        WHEN non_null_actor IS NULL THEN 'Actor not present'
        ELSE 'Actor present'
    END AS actor_status
FROM 
    final_benchmark
WHERE 
    (total_movies_of_year > 10 OR keywords LIKE '%comedy%')
    AND (main_actor <> 'No Cast' OR total_movies_of_year IS NULL)
ORDER BY 
    production_year DESC, title;
