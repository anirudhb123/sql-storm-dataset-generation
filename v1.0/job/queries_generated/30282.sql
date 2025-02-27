WITH RECURSIVE CTE_Movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        level + 1
    FROM 
        CTE_Movies c
    JOIN 
        movie_link ml ON c.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        c.level < 3
),

CTE_Cast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM 
        cast_info ci
    JOIN 
        movie_companies mc ON mc.movie_id = ci.movie_id
    WHERE 
        mc.company_id IS NOT NULL
    GROUP BY 
        ci.movie_id
),

CTE_Keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

CTE_Complete AS (
    SELECT 
        DISTINCT m.id AS movie_id,
        m.title,
        m.production_year,
        c.actor_count,
        k.keyword_list,
        COALESCE(ci.info, 'No Info') AS info
    FROM 
        CTE_Movies m
    LEFT JOIN 
        CTE_Cast c ON m.movie_id = c.movie_id
    LEFT JOIN 
        CTE_Keywords k ON m.movie_id = k.movie_id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        person_info ci ON ci.person_id = (
            SELECT person_id 
            FROM cast_info 
            WHERE movie_id = m.movie_id 
            LIMIT 1
        )
)

SELECT 
    c.title,
    c.production_year,
    c.actor_count,
    c.keyword_list,
    CASE 
        WHEN c.actor_count > 5 THEN 'Large Cast' 
        ELSE 'Small Cast' 
    END AS cast_size_category,
    ROW_NUMBER() OVER (ORDER BY c.production_year DESC) AS rank
FROM 
    CTE_Complete c
WHERE 
    c.actor_count IS NOT NULL
ORDER BY 
    c.production_year DESC, c.actor_count DESC
LIMIT 50;
