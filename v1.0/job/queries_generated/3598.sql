WITH RankedTitles AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS ProductionYear,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS TitleRank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS TotalActors
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(ac.TotalActors, 0) AS ActorCount,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = t.id) AS InfoCount
    FROM 
        title t
    LEFT JOIN 
        ActorCounts ac ON t.id = ac.movie_id
)
SELECT 
    md.MovieTitle,
    md.ProductionYear,
    md.ActorCount,
    md.InfoCount,
    CASE 
        WHEN md.ActorCount > 10 THEN 'Large Cast'
        WHEN md.ActorCount BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS CastSize,
    COALESCE(NULLIF(md.InfoCount, 0), 'No Info') AS InfoAvailability
FROM 
    MovieDetails md
WHERE 
    md.ProductionYear >= 2000
    AND md.ActorCount IS NOT NULL
ORDER BY 
    md.ProductionYear DESC,
    md.ActorCount DESC;

WITH RecentMovies AS (
    SELECT 
        m.id AS MovieID,
        COUNT(DISTINCT mk.keyword_id) AS KeywordsCount
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2015
    GROUP BY 
        m.id
),
TopKeywords AS (
    SELECT 
        m.MovieID,
        k.keyword AS TopKeyword
    FROM 
        RecentMovies m
    JOIN 
        movie_keyword mk ON m.MovieID = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.KeywordsCount > 5
    ORDER BY 
        m.KeywordsCount DESC
)
SELECT 
    m.title,
    tk.TopKeyword
FROM 
    title m
JOIN 
    TopKeywords tk ON m.id = tk.MovieID
ORDER BY 
    m.title;
