WITH movie_statistics AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE 
                WHEN c.nr_order IS NOT NULL THEN c.nr_order 
                ELSE 0 
            END) AS avg_cast_order,
        STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS c ON m.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        m.production_year > 1990
        AND m.title NOT LIKE '%Test%'
    GROUP BY 
        m.id
),
director_statistics AS (
    SELECT 
        cp.movie_id, 
        cp.person_id,
        COUNT(*) AS total_movies_directed 
    FROM 
        complete_cast AS cc
    INNER JOIN 
        cast_info AS cp ON cc.subject_id = cp.person_id 
    INNER JOIN 
        movie_companies AS mc ON mc.movie_id = cc.movie_id
    INNER JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind = 'Director'
    GROUP BY 
        cp.movie_id, cp.person_id
),
final_report AS (
    SELECT 
        ms.movie_id,
        ms.total_cast,
        ms.avg_cast_order,
        ms.associated_keywords,
        COALESCE(ds.total_movies_directed, 0) AS total_movies_directed
    FROM 
        movie_statistics AS ms
    LEFT JOIN 
        director_statistics AS ds ON ms.movie_id = ds.movie_id
)
SELECT 
    fr.movie_id,
    fr.total_cast,
    fr.avg_cast_order,
    fr.associated_keywords,
    fr.total_movies_directed,
    CASE 
        WHEN fr.total_movies_directed > 5 THEN 'Prolific Director'
        ELSE 'Emerging Talent'
    END AS director_status,
    CASE 
        WHEN fr.total_cast IS NULL THEN 'Absent Cast'
        ELSE 'Present Cast'
    END AS cast_status
FROM 
    final_report AS fr
WHERE 
    fr.total_cast >= 1
ORDER BY 
    fr.avg_cast_order DESC NULLS LAST, 
    fr.total_movies_directed DESC, 
    fr.movie_id;
