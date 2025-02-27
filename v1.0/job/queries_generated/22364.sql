WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
MayHaveLinks AS (
    SELECT 
        ml.movie_id,
        COUNT(DISTINCT ml.linked_movie_id) AS linked_movies_count
    FROM 
        movie_link ml
    JOIN 
        RankedMovies rm ON ml.movie_id = rm.movie_title
    GROUP BY 
        ml.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ' ORDER BY mi.info_type_id) AS all_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
ActorName AS (
    SELECT 
        ak.name AS actor_name,
        ak.md5sum,
        ci.movie_id
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mh.linked_movies_count, 0) AS linked_movies_count,
    mi.all_info,
    (
        SELECT 
            COUNT(DISTINCT cn.id)
        FROM 
            company_name cn
        JOIN 
            movie_companies mc ON mc.movie_id = rm.movie_id
        WHERE 
            mc.company_id = cn.id
            AND cn.country_code IS NOT NULL
            AND cn.name LIKE 'C%'
    ) AS distinct_countries_count,
    (
        SELECT 
            STRING_AGG(DISTINCT an.actor_name, ', ')
        FROM 
            ActorName an
        WHERE 
            an.movie_id = rm.movie_title
            AND an.md5sum IS NOT NULL
    ) AS actor_names
FROM 
    RankedMovies rm
LEFT JOIN 
    MayHaveLinks mh ON rm.movie_title = mh.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_title = mi.movie_id
WHERE 
    rm.rank_in_year <= 5
AND 
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC,
    rm.cast_count DESC;
