WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        ct.kind AS cast_type,
        kw.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        t.production_year >= 2000 AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
),
ActorStats AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT movie_title) AS total_movies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords_list
    FROM 
        MovieDetails
    GROUP BY 
        actor_id
),
FinalStats AS (
    SELECT 
        a.name AS actor_name,
        ds.total_movies,
        ds.keywords_list
    FROM 
        ActorStats ds
    JOIN 
        aka_name a ON ds.actor_id = a.id
)
SELECT 
    fs.actor_name,
    fs.total_movies,
    fs.keywords_list 
FROM 
    FinalStats fs
ORDER BY 
    fs.total_movies DESC
LIMIT 10;
