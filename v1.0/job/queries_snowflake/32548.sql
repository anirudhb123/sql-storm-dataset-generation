
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        0 AS depth
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.depth + 1
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY m.kind_id ORDER BY m.production_year DESC) AS rn
    FROM 
        MovieHierarchy m
),
TopRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rn = 1
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        TopRankedMovies tm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = tm.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        tm.title, tm.production_year
),
FilteredMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.total_cast,
        md.actor_names,
        CASE 
            WHEN md.total_cast > 10 THEN 'Ensemble Cast'
            WHEN md.total_cast BETWEEN 5 AND 10 THEN 'Moderate Cast'
            ELSE 'Minimal Cast'
        END AS cast_size
    FROM 
        MovieDetails md
    WHERE 
        md.production_year >= 2000
)
SELECT 
    f.title,
    f.production_year,
    f.total_cast,
    f.actor_names,
    f.cast_size
FROM 
    FilteredMovies f
WHERE 
    f.actor_names IS NOT NULL
ORDER BY 
    f.production_year DESC, f.total_cast DESC;
