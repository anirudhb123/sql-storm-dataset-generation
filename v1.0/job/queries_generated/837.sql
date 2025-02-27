WITH MovieStats AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(mi.info_type_id) AS avg_info_type_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
    GROUP BY 
        t.id
),
FilteredMovies AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.total_cast,
        ms.avg_info_type_id,
        ms.associated_keywords,
        ROW_NUMBER() OVER (PARTITION BY ms.production_year ORDER BY ms.total_cast DESC) AS rn
    FROM 
        MovieStats ms
    WHERE 
        ms.total_cast > 0
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.avg_info_type_id,
    fm.associated_keywords
FROM 
    FilteredMovies fm
WHERE 
    fm.rn <= 5
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast DESC;
