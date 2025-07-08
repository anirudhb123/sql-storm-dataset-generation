
WITH RecursiveMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_order
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RecursiveMovies rm
    WHERE 
        rm.title_order <= 5
),
ActorDetails AS (
    SELECT 
        ak.person_id,
        ak.name,
        ci.movie_id,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.id = ci.person_id
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        AD.person_id,
        AD.name AS actor_name,
        AD.nr_order,
        AD.role_order
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywordCounts mkc ON tm.movie_id = mkc.movie_id
    LEFT JOIN 
        ActorDetails AD ON tm.movie_id = AD.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.keyword_count,
    LISTAGG(fm.actor_name, ', ' ORDER BY fm.role_order) WITHIN GROUP (ORDER BY fm.role_order) AS actor_names,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_actors,
    CASE 
        WHEN COUNT(DISTINCT fm.actor_name) > 5 THEN 'Many Actors'
        WHEN COUNT(DISTINCT fm.actor_name) IS NULL THEN 'No actors'
        ELSE 'Few Actors'
    END AS actor_count_description
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.keyword_count
HAVING 
    SUM(CASE WHEN fm.keyword_count > 1 THEN 1 ELSE 0 END) > 0
ORDER BY 
    fm.production_year DESC, fm.title;
