WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.phonetic_code,
        0 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.phonetic_code,
        mh.level + 1
    FROM aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.phonetic_code,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM MovieHierarchy mh
),
FilteredMovies AS (
    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        mv.phonetic_code
    FROM RankedMovies mv
    WHERE 
        mv.rank <= 5
        AND EXISTS (
            SELECT 1
            FROM movie_info mi
            WHERE mi.movie_id = mv.movie_id
            AND mi.info_type_id IN (
                SELECT id FROM info_type WHERE info = 'Genre'
            )
        )
),
CompleteInfo AS (
    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        COALESCE(mi.info, 'Unknown') AS genre,
        COALESCE(aka.name, 'No actor') AS lead_actor
    FROM FilteredMovies mv
    LEFT JOIN movie_info mi ON mv.movie_id = mi.movie_id
    LEFT JOIN cast_info ci ON mv.movie_id = ci.movie_id
    LEFT JOIN aka_name aka ON ci.person_id = aka.person_id
    WHERE 
        ci.nr_order = 1
        OR (ci.nr_order IS NULL AND aka.name IS NOT NULL)
)
SELECT 
    ci.movie_id,
    ci.title,
    ci.production_year,
    ci.genre,
    string_agg(DISTINCT actor.name ORDER BY actor.name) AS co_stars
FROM CompleteInfo ci
LEFT JOIN cast_info cast ON ci.movie_id = cast.movie_id
LEFT JOIN aka_name actor ON cast.person_id = actor.person_id
GROUP BY 
    ci.movie_id,
    ci.title,
    ci.production_year,
    ci.genre
ORDER BY 
    ci.production_year DESC, 
    ci.title;
