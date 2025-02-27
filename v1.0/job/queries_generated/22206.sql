WITH Recursive MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(LEAD(mt.production_year) OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year), 0) AS next_year,
        COUNT(DISTINCT DISTINCT mk.keyword) OVER (PARTITION BY mt.id) AS keyword_count
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
), 
TopRatedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.next_year,
        mh.keyword_count,
        ROW_NUMBER() OVER (ORDER BY mh.production_year DESC, mh.keyword_count DESC) AS rn
    FROM MovieHierarchy mh
    WHERE mh.production_year IS NOT NULL 
        AND mh.production_year BETWEEN 1980 AND 2023
),
NotableActors AS (
    SELECT 
        a.id AS actor_id,
        an.name,
        COUNT(DISTINCT ci.movie_id) AS appearance_count
    FROM aka_name an
    LEFT JOIN cast_info ci ON an.person_id = ci.person_id
    WHERE an.name IS NOT NULL
    GROUP BY a.id, an.name
    HAVING COUNT(DISTINCT ci.movie_id) > 5
),
SelectedMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        na.name AS notable_actor,
        na.appearance_count
    FROM TopRatedMovies tm
    INNER JOIN NotableActors na ON (tm.rn <= 10 AND na.appearance_count > 10)
),
FinalOutput AS (
    SELECT 
        sm.movie_id,
        sm.title,
        sm.production_year,
        sm.notable_actor,
        COALESCE(sm.appearance_count, 0) AS appearance_count,
        CASE 
            WHEN sm.production_year = 0 THEN 'Unknown Year'
            WHEN sm.production_year < 1990 THEN 'Classic'
            ELSE 'Modern'
        END AS era
    FROM SelectedMovies sm
    ORDER BY sm.production_year DESC, sm.appearance_count DESC
)
SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.notable_actor,
    fo.appearance_count,
    fo.era,
    (SELECT COUNT(DISTINCT mc.company_id) 
     FROM movie_companies mc 
     WHERE mc.movie_id = fo.movie_id) AS company_count,
    (SELECT STRING_AGG(DISTINCT ci.note, ', ') 
     FROM cast_info ci 
     WHERE ci.movie_id = fo.movie_id) AS role_notes,
    (SELECT MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info ELSE NULL END)
     FROM movie_info mi 
     WHERE mi.movie_id = fo.movie_id) AS director_info,
    (SELECT COALESCE(MAX(CASE WHEN ki.keyword = 'Action' THEN 1 ELSE 0 END), 0)
     FROM movie_keyword mk 
     JOIN keyword ki ON mk.keyword_id = ki.id 
     WHERE mk.movie_id = fo.movie_id) AS action_keyword
FROM FinalOutput fo
WHERE fo.appearance_count IS NOT NULL
ORDER BY fo.era, fo.production_year DESC;
