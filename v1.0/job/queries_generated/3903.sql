WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TopRatedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(pi.info::numeric) AS average_rating
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            info 
        FROM 
            movie_info 
        WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) AS pi ON m.id = pi.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
    HAVING 
        COUNT(DISTINCT mc.company_id) > 1 AND AVG(pi.info::numeric) > 7
),
NestedQueries AS (
    SELECT 
        c.id AS cast_id,
        ak.name AS actor_name,
        m.title AS movie_title,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = m.id) AS total_cast_members
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        title m ON m.id = c.movie_id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    tm.movie_id,
    tm.title AS top_movie_title,
    (CASE WHEN tq.actor_name IS NULL THEN 'Unknown' ELSE tq.actor_name END) AS lead_actor,
    COALESCE(tm.company_count, 0) AS company_count,
    COALESCE(tm.average_rating, 0) AS average_rating,
    nq.total_cast_members
FROM 
    RankedTitles r
LEFT JOIN 
    TopRatedMovies tm ON r.title_id = tm.movie_id
LEFT JOIN 
    NestedQueries tq ON r.title = tq.movie_title
WHERE 
    r.title_rank <= 5
ORDER BY 
    r.production_year DESC, 
    tm.average_rating DESC, 
    r.title ASC;
