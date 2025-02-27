WITH Recursive_CTE AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        c.nr_order,
        CAST(NULL AS INTEGER) AS parent_movie_id
    FROM 
        cast_info c
    WHERE 
        c.nr_order = 1
    
    UNION ALL
    
    SELECT 
        c.id,
        c.person_id,
        c.movie_id,
        c.nr_order,
        r.cast_id
    FROM 
        cast_info c
    INNER JOIN 
        Recursive_CTE r ON c.movie_id = r.parent_movie_id
    WHERE 
        c.nr_order = r.nr_order + 1
),
Movies_With_Keywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        k.keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
Movie_Companies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT m.company_id) AS company_count,
        STRING_AGG(c.name, '; ') AS company_names
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
),
Movie_Info AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, '; ') AS infos
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    coalesce(k.keyword, 'No Keywords') AS keyword,
    mc.company_count,
    mc.company_names,
    mi.infos,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    Movies_With_Keywords k ON t.id = k.movie_id
LEFT JOIN 
    Movie_Companies mc ON t.id = mc.movie_id
LEFT JOIN 
    Movie_Info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND (mc.company_count IS NULL OR mc.company_count > 1)
ORDER BY 
    actor_name, 
    movie_rank;
