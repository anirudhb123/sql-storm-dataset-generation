WITH RecursiveActorLinks AS (
    SELECT 
        c.person_id,
        ka.name AS actor_name,
        ka.imdb_index AS actor_imdb_index,
        CAST(NULL AS text) AS connection_path,
        0 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name ka ON c.person_id = ka.person_id
    WHERE 
        c.nr_order = 1  -- Start from the primary actor

    UNION ALL

    SELECT 
        c2.person_id,
        ka2.name AS actor_name,
        ka2.imdb_index AS actor_imdb_index,
        CONCAT(ra.connection_path, ' -> ', ka2.name) AS connection_path,
        ra.depth + 1
    FROM 
        RecursiveActorLinks ra
    JOIN 
        cast_info c2 ON ra.movie_id = c2.movie_id
    JOIN 
        aka_name ka2 ON c2.person_id = ka2.person_id
    WHERE 
        c2.nr_order > 1 AND -- Exclude the primary actor to avoid loops
        ra.depth < 10 -- Limit the depth to avoid excessive recursion
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT ra.actor_name) AS total_actors,
        COUNT(DISTINCT m_comp.company_id) AS total_companies 
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_companies m_comp ON m.id = m_comp.movie_id
    LEFT JOIN 
        RecursiveActorLinks ra ON c.person_id = ra.person_id
    WHERE 
        m.production_year = (
            SELECT 
                MAX(production_year) 
            FROM 
                aka_title 
            WHERE 
                kind_id = 1 -- Movie
        )
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    md.total_actors,
    md.total_companies,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_actors DESC) AS ranking
FROM 
    MovieDetails md
WHERE 
    md.total_companies > 5 
    AND md.keyword IS NOT NULL 
    AND (md.title ILIKE '%adventure%' OR md.title ILIKE '%action%')
ORDER BY 
    md.total_actors DESC, md.title ASC
LIMIT 10;

-- To account for potential NULL values, demonstrate NULL checking in output
SELECT 
    COALESCE(md.title, 'Untitled') AS movie_title,
    COUNT(c.id) AS cast_count
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info c ON md.movie_id = c.movie_id
GROUP BY 
    md.title
HAVING 
    COUNT(c.id) IS NOT NULL
ORDER BY 
    cast_count DESC;
