
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1 AS level
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy h ON m.episode_of_id = h.movie_id
),
AggregatedMovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.person_id) AS cast_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
KeywordAnalysis AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        AggregatedMovieInfo m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    ami.title,
    ami.production_year,
    ami.cast_count,
    k.keyword_count,
    CASE 
        WHEN ami.cast_count > 10 THEN 'Large cast'
        WHEN ami.cast_count BETWEEN 5 AND 10 THEN 'Medium cast'
        ELSE 'Small cast'
    END AS cast_size,
    CASE 
        WHEN ami.company_names IS NULL THEN 'No company contributions'
        ELSE ami.company_names
    END AS company_names
FROM 
    AggregatedMovieInfo ami
LEFT JOIN 
    KeywordAnalysis k ON ami.movie_id = k.movie_id
WHERE 
    ami.production_year > 2010 
    AND (k.keyword_count IS NULL OR k.keyword_count > 3)
ORDER BY 
    ami.production_year DESC, ami.cast_count DESC;
