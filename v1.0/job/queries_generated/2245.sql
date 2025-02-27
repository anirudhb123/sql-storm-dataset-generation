WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY YEAR(t.production_year) ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithMovies AS (
    SELECT 
        a.name AS actor_name,
        rm.title,
        rm.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY rm.production_year DESC) AS actor_movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
)
SELECT 
    awm.actor_name,
    awm.title,
    awm.production_year,
    CASE 
        WHEN awm.actor_movie_rank < 5 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS actor_status,
    COALESCE(kw.keyword, 'No Keyword') AS movie_keyword
FROM 
    ActorsWithMovies awm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = awm.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    awm.actor_movie_rank <= 10
ORDER BY 
    awm.actor_name, awm.production_year DESC;
