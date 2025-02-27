WITH RecursiveCTE AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY ca.nr_order) AS actor_rank,
        COALESCE(d.name_pcode_nf, 'UNKNOWN') AS actor_pcode
    FROM 
        cast_info ca
    LEFT JOIN 
        aka_name d ON ca.person_id = d.person_id
),
MovieStats AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id
),
ActorTitles AS (
    SELECT 
        am.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        COALESCE(mt.title, 'Untitled') AS movie_title,
        mt.production_year
    FROM 
        RecursiveCTE am
    INNER JOIN 
        aka_name a ON am.person_id = a.person_id
    INNER JOIN 
        role_type r ON am.movie_id = r.id
    LEFT JOIN 
        aka_title mt ON am.movie_id = mt.id
    WHERE 
        a.name IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_id,
        actor_name,
        actor_role,
        movie_title,
        production_year
    FROM 
        ActorTitles
    WHERE 
        actor_role IN (SELECT role FROM role_type WHERE role LIKE '%lead%')
)
SELECT 
    f.movie_id,
    f.actor_name,
    f.actor_role,
    f.movie_title,
    f.production_year,
    CASE 
        WHEN f.production_year < 2000 THEN 'Classic'
        WHEN f.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent' 
    END AS era,
    m.keyword_count,
    m.cast_count
FROM 
    FilteredMovies f
JOIN 
    MovieStats m ON f.movie_id = m.movie_id
LEFT JOIN 
    company_name cn ON m.movie_id = cn.imdb_id
WHERE 
    (cn.country_code IS NULL OR cn.country_code <> 'USA')
ORDER BY 
    m.cast_count DESC,
    f.production_year ASC
LIMIT 100;
