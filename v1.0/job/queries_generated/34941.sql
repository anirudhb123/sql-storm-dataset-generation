WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_size,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
TopRankedTitles AS (
    SELECT 
        tt.movie_id,
        tt.title,
        tt.production_year,
        tt.cast_size
    FROM 
        TopMovies tt
    WHERE 
        tt.rank <= 3
)
SELECT 
    tt.title, 
    tt.production_year, 
    COALESCE(k.keyword, 'No Keyword') AS movie_keyword,
    COALESCE(cn.name, 'No Company') AS company_name,
    tt.cast_size,
    CONCAT('Title: ', tt.title, ', Year: ', tt.production_year, ', Cast Size: ', tt.cast_size) AS detailed_info
FROM 
    TopRankedTitles tt
LEFT JOIN 
    movie_keyword mk ON tt.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON tt.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    tt.production_year IS NOT NULL
ORDER BY 
    tt.production_year DESC, 
    tt.cast_size DESC;
