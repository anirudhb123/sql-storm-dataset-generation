WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.id = (SELECT MIN(id) FROM aka_title)

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        rm.* 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
FilteredMovies AS (
    SELECT 
        tm.*, 
        cn.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON tm.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.id, cn.name
)

SELECT 
    fm.title,
    fm.production_year,
    fm.company_name,
    COALESCE(fm.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT c.person_id) AS total_cast,
    MAX(p.info) AS person_info
FROM 
    FilteredMovies fm
LEFT JOIN 
    complete_cast cc ON fm.id = cc.movie_id
LEFT JOIN 
    person_info p ON cc.subject_id = p.person_id 
WHERE 
    p.info_type_id IS NULL OR p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Some Specified Info')
GROUP BY 
    fm.id, fm.company_name
ORDER BY 
    total_cast DESC, fm.production_year DESC;
