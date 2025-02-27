WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title m
    JOIN
        movie_keyword mk ON m.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        m.production_year >= 2000
),
FilteredActors AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM
        aka_name ak
    JOIN
        cast_info c ON ak.person_id = c.person_id
    WHERE
        ak.name LIKE '%Smith%'
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    STRING_AGG(DISTINCT fa.actor_name, ', ') AS actor_names,
    STRING_AGG(DISTINCT rm.keyword, ', ') AS movie_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredActors fa ON rm.movie_id = fa.movie_id
WHERE 
    rm.keyword_rank <= 3
GROUP BY 
    rm.movie_id, rm.movie_title, rm.production_year
ORDER BY 
    rm.production_year DESC, rm.movie_title;
