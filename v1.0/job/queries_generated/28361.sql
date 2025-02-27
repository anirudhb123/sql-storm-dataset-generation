WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 5
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
MoviesWithInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(mi.info IS NOT NULL), 0) AS info_count,
        COALESCE(SUM(mk.keyword IS NOT NULL), 0) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title
),
FinalBenchmark AS (
    SELECT 
        t.title,
        t.production_year,
        a.actor_name,
        m.title AS movie_title,
        mi.info_count,
        mk.keyword_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY m.info_count DESC) AS info_rank
    FROM 
        TopTitles t
    JOIN 
        ActorMovies a ON a.movie_id IN (SELECT m.id FROM aka_title m WHERE m.production_year = t.production_year)
    JOIN 
        MoviesWithInfo m ON a.movie_id = m.movie_id 
)
SELECT 
    fb.title,
    fb.production_year,
    fb.actor_name,
    fb.movie_title,
    fb.info_count,
    fb.keyword_count,
    fb.info_rank
FROM 
    FinalBenchmark fb
WHERE 
    fb.info_rank <= 5
ORDER BY 
    fb.production_year, fb.info_rank, fb.actor_name;
