WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id,
        e.title,
        e.production_year,
        h.level + 1,
        h.movie_id AS parent_movie_id
    FROM 
        aka_title AS e
    JOIN 
        MovieHierarchy AS h ON e.episode_of_id = h.movie_id
),
TitleWithKeywords AS (
    SELECT 
        m.movie_id,
        m.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY m.production_year DESC) AS keyword_rank  
    FROM 
        MovieHierarchy AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title
),
TopMovies AS (
    SELECT 
        twk.movie_id,
        twk.title,
        twk.keywords,
        ROW_NUMBER() OVER (ORDER BY twk.keyword_rank DESC) AS rank
    FROM 
        TitleWithKeywords AS twk
    WHERE 
        twk.keywords IS NOT NULL
)
SELECT 
    ta.title AS main_title,
    ta.production_year,
    ak.name AS actor_name,
    cc.kind AS cast_type,
    tm.keywords
FROM 
    aka_title AS ta
JOIN 
    cast_info AS ci ON ta.id = ci.movie_id
JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
LEFT JOIN 
    comp_cast_type AS cc ON ci.role_id = cc.id
LEFT JOIN 
    TopMovies AS tm ON ta.id = tm.movie_id
WHERE 
    tm.rank <= 10 OR (tm.rank IS NULL AND ta.production_year >= 2000)
ORDER BY 
    ta.production_year DESC, 
    ak.name;
