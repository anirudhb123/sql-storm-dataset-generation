WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = 1  -- Assuming 1 is for 'feature movies'
    
    UNION ALL
    
    SELECT 
        t2.id AS movie_id,
        t2.title,
        t2.production_year,
        t2.season_nr,
        t2.episode_nr,
        mh.level + 1
    FROM 
        aka_title t2
    INNER JOIN 
        movie_link ml ON t2.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        t2.kind_id = 1
),
RankedMovies AS (
    SELECT 
        mh.title,
        mh.production_year,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(cc.id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    GROUP BY 
        mh.title, mh.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(ak.name, 'Unknown') AS lead_actor,
    mk.keyword AS movie_keyword,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = tm.movie_id 
     AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Runtime')) AS runtime_info,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM movie_companies mc 
     JOIN company_name cn ON mc.company_id = cn.imdb_id 
     WHERE mc.movie_id = tm.movie_id) AS production_companies
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.movie_id
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
