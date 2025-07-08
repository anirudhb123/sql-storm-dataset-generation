
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
PopularMovies AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        MovieHierarchy mh ON c.movie_id = mh.movie_id
    GROUP BY 
        c.movie_id
    HAVING 
        COUNT(c.person_id) > 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        pm.cast_count,
        mk.keywords_list,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY pm.cast_count DESC) AS rank_order
    FROM 
        MovieHierarchy mh
    JOIN 
        PopularMovies pm ON mh.movie_id = pm.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.cast_count,
    COALESCE(rm.keywords_list, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.rank_order <= 10 THEN 'Top 10'
        ELSE 'Others' 
    END AS rank_category
FROM 
    RankedMovies rm
WHERE 
    rm.rank_order <= 10 OR rm.rank_order > 10
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
