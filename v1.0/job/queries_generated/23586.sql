WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        m.production_year,
        COALESCE(ct.kind, 'Unknown') AS company_type,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY t.title) AS rank
    FROM
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        m.id, t.title, m.production_year, ct.kind
),
actor_summary AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ch.movie_id) AS movie_count,
        COUNT(DISTINCT CASE WHEN ch.status_id = 1 THEN ch.movie_id END) AS active_movies,
        MAX(m.production_year) AS latest_movie_year
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        complete_cast ch ON c.movie_id = ch.movie_id
    LEFT JOIN 
        aka_title m ON c.movie_id = m.id
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    mh.movie_title,
    mh.production_year,
    mh.company_type,
    mh.actor_names,
    a.name AS actor_name,
    a.movie_count,
    a.active_movies,
    a.latest_movie_year
FROM 
    movie_hierarchy mh
JOIN 
    actor_summary a ON a.latest_movie_year = mh.production_year AND mh.actor_names @> ARRAY[a.name]::text[]
WHERE 
    (mh.rank <= 10 OR mh.company_type IS NOT NULL)
    AND (a.movie_count > 5 OR a.latest_movie_year IS NULL)
    AND NOT EXISTS (
        SELECT 1
        FROM movie_keyword mk
        WHERE mk.movie_id = mh.movie_id
        AND mk.keyword_id = (SELECT id FROM keyword WHERE keyword = 'flop')
    )
ORDER BY 
    mh.production_year DESC, 
    a.movie_count DESC;
