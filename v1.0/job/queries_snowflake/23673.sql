
WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(k.keyword) DESC) AS title_rank,
        t.id AS title_id,
        t.imdb_index
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, t.imdb_index
),
actor_data AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movies_with_role,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS num_null_notes,
        MAX(CASE 
            WHEN ci.nr_order IS NOT NULL AND ci.nr_order <> 0 THEN 1 
            ELSE 0 
        END) AS has_valid_order
    FROM 
        aka_name AS a
    INNER JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
),
movie_info_data AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS all_info,
        AVG(LENGTH(mi.info)) AS avg_info_length
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ad.name AS actor_name,
    ad.movies_with_role,
    ad.num_null_notes,
    ad.has_valid_order,
    mid.all_info,
    mid.avg_info_length
FROM 
    ranked_titles rt
LEFT JOIN 
    (SELECT * FROM actor_data WHERE movies_with_role > 2) ad ON rt.title_id = ad.person_id 
LEFT JOIN 
    movie_info_data mid ON rt.title_id = mid.movie_id
WHERE 
    rt.title_rank = 1 
    AND (ad.movies_with_role IS NULL OR ad.has_valid_order = 1)
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
