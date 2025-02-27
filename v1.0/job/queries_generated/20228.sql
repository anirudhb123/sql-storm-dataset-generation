WITH RECURSIVE movie_chain AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS depth, 
        m.production_year,
        t.id AS title_id 
    FROM 
        aka_title m 
    JOIN 
        kind_type k ON m.kind_id = k.id
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    WHERE 
        k.kind LIKE 'movie%'
    UNION ALL
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        mc.depth + 1,
        t.production_year,
        t.id AS title_id
    FROM 
        movie_chain mc
    JOIN 
        movie_link ml ON mc.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
),
genre_count AS (
    SELECT 
        mt.keyword AS genre,
        COUNT(DISTINCT mc.movie_id) AS genre_movie_count
    FROM 
        movie.keyword mt
    JOIN 
        movie_keyword mk ON mt.id = mk.keyword_id
    JOIN 
        aka_title at ON mk.movie_id = at.id
    WHERE 
        mt.keyword IS NOT NULL
    GROUP BY 
        mt.keyword
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 2
),
cast_and_company AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        cast_info ci
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    g.genre,
    g.genre_movie_count,
    c.cast_count,
    c.company_count,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.cast_count DESC) AS rank_by_cast
FROM 
    movie_chain m
JOIN 
    genre_count g ON m.movie_title = g.genre
JOIN 
    cast_and_company c ON m.movie_id = c.movie_id
WHERE 
    m.production_year IS NOT NULL
    AND g.genre_movie_count > c.cast_count
    AND (c.company_count > 0 OR c.cast_count IS NULL)
ORDER BY 
    m.production_year DESC, c.cast_count DESC;
