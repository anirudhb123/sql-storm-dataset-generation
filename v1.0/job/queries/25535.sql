WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        at.kind_id,
        COUNT(mk.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(mk.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    GROUP BY 
        at.id, at.title, at.production_year, at.kind_id
),
PopularActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
),
TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        pc.person_id,
        pc.name AS actor_name,
        rt.keyword_count
    FROM 
        RankedTitles rt
    JOIN 
        cast_info ci ON rt.title_id = ci.movie_id
    JOIN 
        PopularActors pc ON ci.person_id = pc.person_id
    WHERE 
        rt.rank <= 5 AND pc.rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_name,
    tm.keyword_count
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.keyword_count DESC;
