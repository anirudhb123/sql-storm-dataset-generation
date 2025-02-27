
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(mt.season_nr, 0), -1) AS season_nr,
        COALESCE(NULLIF(mt.episode_nr, 0), -1) AS episode_nr,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL
    
    SELECT 
        mlt.id AS movie_id,
        mlt.title,
        mlt.production_year,
        COALESCE(NULLIF(mlt.season_nr, 0), -1) AS season_nr,
        COALESCE(NULLIF(mlt.episode_nr, 0), -1) AS episode_nr,
        mh.level + 1
    FROM 
        aka_title mlt
    INNER JOIN 
        MovieHierarchy mh ON mlt.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.title,
        mh.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.title, mh.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    mci.note AS production_notes
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON tm.production_year = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
LEFT JOIN 
    movie_companies mci ON tm.production_year = mci.movie_id
GROUP BY 
    tm.title, tm.production_year, tm.actor_count, mci.note
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
