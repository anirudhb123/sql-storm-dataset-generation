WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
ActorFilmCounts AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) as film_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
),
HighestRatedActors AS (
    SELECT 
        a.name,
        afc.film_count
    FROM 
        ActorFilmCounts afc
    JOIN 
        (SELECT 
             a.person_id,
             AVG(COALESCE(mvi.rating, 0)) AS avg_rating
         FROM 
             aka_name a
         JOIN 
             cast_info ci ON a.person_id = ci.person_id
         LEFT JOIN 
             movie_info mvi ON ci.movie_id = mvi.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
         GROUP BY 
             a.person_id) sub ON afc.name = sub.name
    WHERE 
        sub.avg_rating > 7.5
)
SELECT 
    r.title,
    r.production_year,
    r.company_count,
    h.name AS top_actor,
    h.film_count
FROM 
    RankedMovies r
JOIN 
    HighestRatedActors h ON r.rank <= 3
WHERE 
    r.company_count > 1
ORDER BY 
    r.production_year DESC, r.company_count DESC;
