WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS ranking
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
PopularGenres AS (
    SELECT 
        kt.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword kt
    JOIN 
        movie_keyword mk ON kt.id = mk.keyword_id
    GROUP BY 
        kt.keyword
    HAVING 
        COUNT(mk.movie_id) > 10
),
ActorsWithRoles AS (
    SELECT 
        a.id as actor_id,
        ak.name AS actor_name,
        a.name_pcode_nf,
        c.role_id,
        r.role AS role_name
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        ak.name IS NOT NULL
),
MoviesWithWideRange AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        COALESCE(AVG(mi.info::INT), 0) AS average_rating,
        SUM(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count, 
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id 
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id 
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id 
    WHERE 
        m.production_year BETWEEN 1980 AND 2020
    GROUP BY 
        m.id
    HAVING 
        COUNT(DISTINCT kw.id) > 5 OR AVG(mi.info::INT) > 7
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    CASE 
        WHEN r.production_year < 2000 THEN 'Classic'
        WHEN r.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    p.keyword,
    a.actor_name,
    a.role_name,
    mw.average_rating,
    mw.note_count
FROM 
    RankedMovies r
LEFT JOIN 
    PopularGenres p ON p.movie_count > 15
LEFT JOIN 
    ActorsWithRoles a ON r.movie_id IN (SELECT DISTINCT c.movie_id FROM cast_info c WHERE c.person_role_id IS NOT NULL)
LEFT JOIN 
    MoviesWithWideRange mw ON r.movie_id = mw.movie_id
WHERE 
    mw.average_rating IS NOT NULL AND mw.note_count > 0
ORDER BY 
    r.production_year DESC, mw.average_rating DESC;
