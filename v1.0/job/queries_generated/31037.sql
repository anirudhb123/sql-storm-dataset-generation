WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON a.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3
),
MovieInfo AS (
    SELECT 
        title.id AS title_id,
        title.title,
        COALESCE(mi.info, 'No Info Available') AS info,
        COALESCE(c.name, 'Unknown') AS company_name
    FROM 
        title
    LEFT JOIN 
        movie_info mi ON title.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary' LIMIT 1)
    LEFT JOIN 
        movie_companies mc ON title.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
),
RankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        info,
        company_name,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS rank_in_year
    FROM 
        MovieInfo
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        info,
        company_name,
        rank_in_year
    FROM 
        RankedMovies
    WHERE 
        rank_in_year <= 5
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    tm.info,
    tm.company_name,
    mh.level AS hierarchy_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopMovies tm ON mh.movie_id = tm.movie_id
WHERE 
    tm.movie_id IS NOT NULL
ORDER BY 
    mh.production_year DESC, 
    mh.level, 
    mh.title;
