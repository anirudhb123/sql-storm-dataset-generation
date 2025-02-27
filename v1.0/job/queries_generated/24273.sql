WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        c.kind AS movie_type,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title ASC) AS rank_by_year
    FROM 
        aka_title a
    JOIN 
        kind_type c ON a.kind_id = c.id
    WHERE 
        a.production_year IS NOT NULL
    AND 
        a.title IS NOT NULL
),
TopMovies AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        rank_by_year <= 5
    GROUP BY 
        production_year
),
RelatedMovies AS (
    SELECT 
        mt.title AS original_title,
        linked.title AS linked_title,
        lt.link AS link_type
    FROM 
        movie_link ml 
    JOIN 
        title mt ON ml.movie_id = mt.id
    JOIN 
        title linked ON ml.linked_movie_id = linked.id
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
    WHERE 
        lt.link IS NOT NULL
)

SELECT 
    r.production_year,
    r.movie_count,
    COALESCE(rt.original_title, 'No Link') AS original_movie,
    COALESCE(rt.linked_title, 'No Link') AS linked_movie,
    COUNT(rt.linked_title) OVER (PARTITION BY r.production_year) AS total_linked_movies,
    CONCAT_WS(' - ', COALESCE(rt.linked_title, 'Unknown'), COALESCE(r.movie_count::text, '0 Movies')) AS summary_info
FROM 
    TopMovies r
LEFT JOIN 
    RelatedMovies rt ON r.production_year = (SELECT production_year FROM RankedMovies WHERE rank_by_year <= 5 LIMIT 1)
ORDER BY 
    r.production_year DESC, r.movie_count DESC;

-- Additional NULL logic and bizarre semantics
SELECT 
    DISTINCT ON (m.id) 
    m.title,
    COALESCE(ci.id, -1) AS cast_id,
    n.name AS actor_name,
    CASE 
        WHEN m.production_year IS NULL THEN 'Unknown Year'
        ELSE m.production_year::text
    END AS production_year,
    CASE 
        WHEN n.md5sum IS NULL THEN 'MD5 Sum Missing'
        ELSE n.md5sum 
    END AS actor_md5
FROM 
    aka_title m
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
WHERE 
    (m.production_year IS NOT NULL OR m.title ILIKE '%Mystery%')
    AND (n.name IS NOT NULL OR ci.note IS NULL)
ORDER BY 
    m.production_year DESC NULLS LAST,
    m.title ASC;
