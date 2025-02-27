
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
AwardWinningMovies AS (
    SELECT 
        DISTINCT m.movie_id,
        m.movie_title,
        m.production_year
    FROM 
        RankedMovies m
    JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info ILIKE '%award%'
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
FinalOutput AS (
    SELECT 
        m.movie_title,
        m.production_year,
        a.actor_name,
        a.role_name,
        COUNT(DISTINCT a.movie_id) AS actor_movie_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        AwardWinningMovies m
    LEFT JOIN 
        CastDetails a ON m.movie_id = a.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.movie_title, m.production_year, a.actor_name, a.role_name
    ORDER BY 
        m.production_year DESC, actor_movie_count DESC, m.movie_title
)
SELECT 
    *
FROM 
    FinalOutput
WHERE 
    actor_movie_count > 1
LIMIT 50;
