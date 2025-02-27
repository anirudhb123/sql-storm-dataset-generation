WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY c.nr_order) AS actor_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
), ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        rm.movie_id,
        rm.title
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    INNER JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
), TopActors AS (
    SELECT 
        ad.name,
        ad.movie_id,
        ad.title,
        RANK() OVER (ORDER BY COUNT(ad.person_id) DESC) AS actor_rank
    FROM 
        ActorDetails ad
    GROUP BY 
        ad.name, ad.movie_id, ad.title
)
SELECT 
    ta.name,
    ta.title,
    ta.actor_rank,
    COALESCE((SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = ta.movie_id AND mi.info_type_id = 1), 0) AS info_count,
    (SELECT STRING_AGG(DISTINCT kw.keyword, ', ') 
     FROM movie_keyword mk
     JOIN keyword kw ON mk.keyword_id = kw.id
     WHERE mk.movie_id = ta.movie_id) AS keywords
FROM 
    TopActors ta
WHERE 
    ta.actor_rank <= 5
ORDER BY 
    ta.actor_rank, ta.title;
