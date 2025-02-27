
WITH MoviesWithCast AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        STRING_AGG(a.name, ',' ORDER BY c.nr_order) AS cast_names,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.cast_names,
        m.production_year,
        m.total_cast,
        m.keywords,
        STRING_AGG(mi.info, ',') AS additional_info
    FROM 
        MoviesWithCast m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id, m.title, m.cast_names, m.production_year, m.total_cast, m.keywords
),
FinalBenchmark AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.total_cast,
        mw.cast_names,
        mw.keywords,
        CASE 
            WHEN mw.additional_info IS NOT NULL THEN 'Has Info' 
            ELSE 'No Info' 
        END AS info_status
    FROM 
        MoviesWithInfo mw
    WHERE 
        mw.production_year >= 2000
)

SELECT 
    fb.title,
    fb.production_year,
    fb.total_cast,
    fb.cast_names,
    fb.keywords,
    fb.info_status
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.production_year DESC,
    fb.total_cast DESC
LIMIT 100;
