
WITH ranked_cast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        an.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_filtered AS (
    SELECT 
        mi.movie_id,
        COUNT(*) FILTER (WHERE it.info = 'rating') AS rating_count,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS last_rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    t.title,
    t.production_year,
    an.name AS actor_name,
    rk.role_rank,
    mk.keywords,
    mif.rating_count,
    mif.last_rating
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    ranked_cast rk ON t.id = rk.movie_id
LEFT JOIN 
    aka_name an ON rk.person_id = an.person_id
LEFT JOIN 
    movie_keywords mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info_filtered mif ON t.id = mif.movie_id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Drama%')
    AND (mif.last_rating IS NOT NULL OR mk.keywords IS NOT NULL)
    AND (an.name IS NOT NULL OR rk.role_rank = 1)
ORDER BY 
    t.production_year DESC,
    rk.role_rank ASC
LIMIT 100;
