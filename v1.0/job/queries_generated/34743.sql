WITH RECURSIVE RecursiveCTE AS (
    SELECT 
        movie_id,
        title,
        production_year,
        1 AS depth,
        title AS full_title
    FROM 
        aka_title
    WHERE 
        kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        mc.movie_id,
        at.title,
        at.production_year,
        r.depth + 1,
        CONCAT(r.full_title, ' -> ', at.title) AS full_title
    FROM 
        complete_cast mc
    INNER JOIN 
        aka_title at ON mc.movie_id = at.movie_id
    INNER JOIN 
        RecursiveCTE r ON mc.subject_id = r.movie_id
    WHERE 
        mc.status_id = 1  -- Assuming 1 means active
),
MovieStats AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        COUNT(ci.id) AS cast_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        AVG(pi.info_length) AS avg_person_info_length
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN (
        SELECT 
            person_id,
            AVG(LENGTH(info)) AS info_length
        FROM 
            person_info
        GROUP BY 
            person_id
    ) pi ON ci.person_id = pi.person_id
    GROUP BY 
        at.id, at.title
),
Benchmark AS (
    SELECT 
        m.movie_id,
        m.title,
        m.cast_count,
        m.keywords,
        ms.avg_person_info_length,
        CASE 
            WHEN m.cast_count IS NULL THEN 0
            ELSE m.cast_count
        END AS valid_cast_count
    FROM 
        MovieStats m
    LEFT JOIN 
        (SELECT 
             movie_id,
             SUM(CASE WHEN kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') THEN 1 ELSE 0 END) AS movie_count 
         FROM 
             aka_title 
         GROUP BY 
             movie_id) ms ON ms.movie_id = m.movie_id
)
SELECT 
    b.title,
    b.cast_count,
    b.keywords,
    b.avg_person_info_length,
    RANK() OVER (ORDER BY b.valid_cast_count DESC) AS cast_rank
FROM 
    Benchmark b
WHERE 
    b.cast_count > 0
ORDER BY 
    b.cast_rank, b.title;
