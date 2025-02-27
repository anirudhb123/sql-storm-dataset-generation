WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        title t
),
TopRatedMovies AS (
    SELECT 
        t.title_name,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        RankedTitles t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        title_rank <= 5
    GROUP BY 
        t.title_name, t.production_year, t.kind_id
),
ActorsWithMostTitles AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ct.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    JOIN 
        RankedTitles rt ON cc.movie_id = rt.title_id
    GROUP BY 
        a.name
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
KeywordStats AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    ORDER BY 
        movie_count DESC
    LIMIT 5
)
SELECT 
    t.title_name,
    t.production_year,
    a.actor_name,
    a.movie_count,
    k.keyword,
    k.movie_count AS keyword_movie_count
FROM 
    TopRatedMovies t
JOIN 
    ActorsWithMostTitles a ON a.movie_count > 2
JOIN 
    KeywordStats k ON k.movie_count > 10
ORDER BY 
    t.production_year DESC, a.movie_count DESC, k.movie_count DESC;
