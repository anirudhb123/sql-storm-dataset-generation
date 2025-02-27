WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithAlias AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        COALESCE(MAX(c.nr_order), 0) AS max_order
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
),
MoviesWithInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COALESCE(mi.info, 'No info available') AS additional_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info='Synopsis' LIMIT 1)
    GROUP BY 
        m.id, m.title, mi.info
)
SELECT 
    m.title,
    m.production_year,
    a.name AS actor_name,
    a.movie_count,
    COALESCE(r.cast_count, 0) AS total_cast,
    COALESCE(mw.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN r.rank_within_year <= 5 THEN 'Top 5'
        ELSE 'Not Top 5'
    END AS rank_category,
    a.max_order
FROM 
    RankedMovies r
INNER JOIN 
    MoviesWithInfo mw ON r.title = mw.title
LEFT JOIN 
    ActorsWithAlias a ON a.movie_count > 1
WHERE 
    COALESCE(mw.additional_info, '') IS NOT NULL
AND 
    (a.max_order IS NULL OR a.max_order > 0)
ORDER BY 
    r.production_year DESC, total_cast DESC, m.title;
