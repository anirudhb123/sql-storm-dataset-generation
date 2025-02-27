WITH Recursive CastTree AS (
    SELECT 
        c.movie_id,
        ca.person_id,
        1 AS depth,
        ARRAY[ca.person_id] AS path
    FROM 
        cast_info ca
    JOIN 
        title t ON ca.movie_id = t.id
    WHERE 
        t.production_year = 2023 AND ca.nr_order = 1

    UNION ALL

    SELECT 
        c.movie_id,
        c.person_id,
        ct.depth + 1,
        path || c.person_id
    FROM 
        cast_info c
    JOIN 
        CastTree ct ON c.movie_id = ct.movie_id
    WHERE 
        ct.person_id <> c.person_id AND NOT c.person_id = ANY(ct.path)
),

MovieAwards AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT ma.id) AS award_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Award')
    JOIN 
        movie_info_idx mai ON mi.id = mai.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000 AND m.production_year <= 2023
    GROUP BY 
        m.id
)

SELECT 
    t.title,
    COALESCE(a.award_count, 0) AS total_awards,
    ct.person_id,
    ct.depth,
    CASE 
        WHEN a.award_count IS NULL THEN 'Unknown'
        WHEN a.award_count < 3 THEN 'Few Awards'
        ELSE 'Acclaimed'
    END AS award_status,
    STRING_AGG(DISTINCT ak.name, ', ') AS co_actors,
    (SELECT ARRAY_AGG(DISTINCT c.note) 
     FROM cast_info c 
     WHERE c.movie_id = t.id AND c.note IS NOT NULL) AS notes
FROM 
    title t
LEFT JOIN 
    MovieAwards a ON t.id = a.movie_id
LEFT JOIN 
    CastTree ct ON t.id = ct.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ct.person_id
WHERE 
    ct.depth <= 3
GROUP BY 
    t.id, a.award_count, ct.person_id, ct.depth
ORDER BY 
    total_awards DESC, t.title ASC;
