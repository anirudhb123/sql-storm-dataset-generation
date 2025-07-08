
WITH RecursiveMovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title AS original_title,
        t.production_year,
        LISTAGG(DISTINCT m.keyword, ', ') WITHIN GROUP (ORDER BY m.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS ranking
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword m ON mk.keyword_id = m.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredCast AS (
    SELECT 
        ci.movie_id, 
        a.name AS actor_name,
        c.kind AS role_type,
        DENSE_RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS ranking
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    WHERE 
        a.name IS NOT NULL
),
ChainedMovies AS (
    SELECT 
        ml.movie_id AS source_movie, 
        ml.linked_movie_id AS target_movie,
        lt.link AS relationship_type,
        ROW_NUMBER() OVER (PARTITION BY ml.movie_id ORDER BY lt.link) AS link_rank
    FROM 
        movie_link ml
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
    WHERE 
        ml.linked_movie_id IS NOT NULL
),
AggregateKeywords AS (
    SELECT 
        t.id AS movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS all_keywords
    FROM 
        title t 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)

SELECT 
    m.movie_id,
    m.original_title,
    m.production_year,
    fk.actor_name,
    fk.role_type,
    ak.all_keywords,
    COUNT(DISTINCT cm.target_movie) AS linked_movies_count
FROM 
    RecursiveMovieInfo m
LEFT JOIN 
    FilteredCast fk ON m.movie_id = fk.movie_id
LEFT JOIN 
    AggregateKeywords ak ON m.movie_id = ak.movie_id
LEFT JOIN 
    ChainedMovies cm ON m.movie_id = cm.source_movie
WHERE 
    m.production_year > 1990
    AND (fk.actor_name IS NOT NULL OR ak.all_keywords IS NOT NULL)
GROUP BY 
    m.movie_id, m.original_title, m.production_year, fk.actor_name, fk.role_type, ak.all_keywords
HAVING 
    COUNT(DISTINCT fk.actor_name) > 1 OR COUNT(DISTINCT ak.all_keywords) > 0
ORDER BY 
    m.production_year DESC, linked_movies_count DESC, fk.actor_name ASC;
