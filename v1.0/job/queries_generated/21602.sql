WITH ranked_movies AS (
    SELECT 
        m.id as movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) as rank_in_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
actors AS (
    SELECT 
        p.id as person_id,
        ak.name as actor_name,
        COUNT(c.movie_id) as movie_count,
        STRING_AGG(DISTINCT m.title, ', ') as movies_starred
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    GROUP BY 
        p.id, ak.name
),
companies AS (
    SELECT 
        mc.movie_id,
        c.name as company_name,
        MAX(c.country_code) as country_of_origin
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id, c.name
),
titles_with_keywords AS (
    SELECT 
        m.id as movie_id,
        m.title, 
        k.keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
)
SELECT 
    ak.actor_name,
    rm.title,
    rm.production_year,
    co.country_of_origin,
    ak.movie_count,
    COALESCE(tkw.keyword, 'No keyword') as keyword
FROM 
    ranked_movies rm
JOIN 
    actors ak ON rm.movie_id = ak.movie_id
LEFT JOIN 
    companies co ON rm.movie_id = co.movie_id
LEFT JOIN 
    titles_with_keywords tkw ON rm.movie_id = tkw.movie_id
WHERE 
    ak.movie_count > (
        SELECT 
            AVG(movie_count) 
        FROM 
            actors
    )
    AND rm.rank_in_year <= 3
ORDER BY 
    rm.production_year DESC, ak.movie_count DESC;

WITH RECURSIVE cast_hierarchy AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        1 as level
    FROM 
        cast_info ci
    WHERE 
        ci.note IS NOT NULL

    UNION ALL

    SELECT 
        ci.movie_id,
        ci.person_id,
        ch.level + 1
    FROM 
        cast_info ci
    JOIN 
        cast_hierarchy ch ON ci.movie_id = ch.movie_id
    WHERE 
        ci.person_role_id IS NOT NULL
)
SELECT 
    COUNT(*) as total_cast_in_hierarchy,
    MAX(ch.level) as max_level
FROM 
    cast_hierarchy ch
WHERE 
    EXISTS (
        SELECT 1 
        FROM actors a 
        WHERE a.person_id = ch.person_id
    )
    AND ch.level > 1;

SELECT DISTINCT 
    COALESCE(NULLIF(k.keyword, ''), 'UNKNOWN') as keyword_status,
    COUNT(m.id) AS movie_count
FROM 
    aka_title m
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    keyword_status
HAVING 
    COUNT(m.id) > 5 
ORDER BY 
    movie_count DESC;
