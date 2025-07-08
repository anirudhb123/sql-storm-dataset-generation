
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast co ON mt.id = co.movie_id
    LEFT JOIN 
        cast_info cc ON co.subject_id = cc.id
    GROUP BY 
        mt.title, mt.production_year
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        LISTAGG(DISTINCT ti.title, ', ') WITHIN GROUP (ORDER BY ti.title) AS movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title ti ON ci.movie_id = ti.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10 AND rm.cast_count > 2
)
SELECT 
    fm.title,
    fm.production_year,
    am.actor_name,
    am.movie_count,
    am.movies
FROM 
    FilteredMovies fm
LEFT JOIN 
    ActorInfo am ON fm.cast_count = am.movie_count
WHERE 
    fm.production_year IS NOT NULL
ORDER BY 
    fm.production_year DESC, fm.title;
