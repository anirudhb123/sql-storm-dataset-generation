
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title AS MovieTitle,
        mt.production_year,
        mt.id AS MovieID,
        ARRAY_CONSTRUCT(mt.id) AS MoviePath
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.title AS MovieTitle,
        mt.production_year,
        mt.id AS MovieID,
        ARRAY_CAT(mh.MoviePath, ARRAY_CONSTRUCT(mt.id)) AS MoviePath
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.MovieID
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS RoleCount
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        ak.name,
        ar.RoleCount,
        RANK() OVER (ORDER BY ar.RoleCount DESC) AS ActorRank
    FROM 
        aka_name ak
    JOIN 
        ActorRoleCounts ar ON ak.person_id = ar.person_id
    WHERE 
        ak.name IS NOT NULL
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS KeywordCount
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
AllMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COALESCE(mkc.KeywordCount, 0) AS TotalKeywords,
        mh.MoviePath,
        ARRAY_SIZE(mh.MoviePath) AS PathLength,
        mt.id AS movie_id
    FROM 
        aka_title mt
    LEFT JOIN 
        MovieKeywordCounts mkc ON mt.id = mkc.movie_id
    JOIN 
        MovieHierarchy mh ON mt.id = mh.MovieID
)
SELECT 
    am.title,
    am.production_year,
    am.TotalKeywords,
    ta.name AS TopActor,
    ta.RoleCount,
    (CASE 
        WHEN am.PathLength > 5 THEN 'Long Series'
        WHEN am.PathLength = 1 THEN 'Standalone Movie'
        ELSE 'Medium Series'
    END) AS SeriesType,
    (SELECT LISTAGG(DISTINCT c.note, ', ') 
     FROM cast_info c 
     WHERE c.movie_id = am.movie_id AND c.note IS NOT NULL) AS CastNotes
FROM 
    AllMovies am
LEFT JOIN 
    TopActors ta ON ta.ActorRank <= 5
WHERE 
    am.TotalKeywords > 0
GROUP BY 
    am.title, 
    am.production_year, 
    am.TotalKeywords, 
    ta.name, 
    ta.RoleCount, 
    am.PathLength, 
    am.movie_id
ORDER BY 
    am.TotalKeywords DESC, 
    am.production_year DESC
LIMIT 10;
