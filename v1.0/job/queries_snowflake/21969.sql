
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN mi.info END) AS rating,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title
),
cast_info_details AS (
    SELECT 
        ci.movie_id,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_members,
        COUNT(DISTINCT ci.role_id) AS roles_count,
        COUNT(DISTINCT ci.nr_order) AS nr_order_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
final_benchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.rating,
        md.production_companies,
        cid.cast_members,
        cid.roles_count,
        cid.nr_order_count
    FROM 
        movie_details md
    LEFT JOIN 
        cast_info_details cid ON md.movie_id = cid.movie_id
),
ranked_movies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY rating ORDER BY production_companies DESC) AS rank
    FROM 
        final_benchmark
    WHERE 
        rating IS NOT NULL OR production_companies > 2
)
SELECT 
    *,
    CASE 
        WHEN rank IS NULL THEN 'No Rank Assigned'
        ELSE CAST(rank AS VARCHAR) || ' - Ranked'
    END AS rank_info,
    COALESCE(cast_members, 'No Cast Information') AS cast_info
FROM 
    ranked_movies
WHERE 
    (production_companies > 3 OR roles_count > 4)
    AND rating IS NOT NULL
    AND title LIKE '%The%'
ORDER BY 
    production_companies DESC, rating DESC;
