
WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mcte.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieCTE mcte ON mt.episode_of_id = mcte.movie_id
),
DirectorCTE AS (
    SELECT 
        ci.movie_id,
        a.name AS director_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS director_orders
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.role_id IN (SELECT id FROM role_type WHERE role = 'Director')
),
KeywordCTE AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfoCTE AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS highest_rating,
        COUNT(DISTINCT mi.id) AS info_count
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mcte.title,
    mcte.production_year,
    d.director_name,
    COALESCE(ki.keywords, 'No Keywords') AS movie_keywords,
    mict.highest_rating,
    mict.info_count
FROM 
    MovieCTE mcte
LEFT JOIN 
    DirectorCTE d ON mcte.movie_id = d.movie_id
LEFT JOIN 
    KeywordCTE ki ON mcte.movie_id = ki.movie_id
LEFT JOIN 
    MovieInfoCTE mict ON mcte.movie_id = mict.movie_id
WHERE 
    mcte.level = 1
    AND (mict.highest_rating IS NOT NULL OR d.director_name IS NOT NULL)
ORDER BY 
    mcte.production_year DESC, 
    mcte.title;
