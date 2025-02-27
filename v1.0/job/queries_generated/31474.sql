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
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CompanyMovieCount AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        movie_companies mc
    INNER JOIN 
        aka_title m ON mc.movie_id = m.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        mc.company_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cc.movie_count, 0) AS company_count,
        COALESCE(ks.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY mh.production_year DESC, mh.title) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CompanyMovieCount cc ON cc.company_id = (SELECT DISTINCT mc.company_id 
                                                  FROM movie_companies mc 
                                                  WHERE mc.movie_id = mh.movie_id
                                                  LIMIT 1)
    LEFT JOIN 
        KeywordStats ks ON ks.movie_id = mh.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.keyword_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 50
ORDER BY 
    tm.keyword_count DESC, 
    tm.production_year ASC;
