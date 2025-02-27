WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL  -- start with top-level movies (not episodes)

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id  -- get episodes
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cc.id) AS total_cast,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(cc.id) DESC) AS rank_within_year
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_within_year <= 5  -- top 5 movies per year
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.total_cast
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    COALESCE(md.actor_names, 'No Cast Available') AS actor_names,
    CASE 
        WHEN md.total_cast > 10 THEN 'Large Cast'
        WHEN md.total_cast BETWEEN 5 AND 10 THEN 'Average Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
