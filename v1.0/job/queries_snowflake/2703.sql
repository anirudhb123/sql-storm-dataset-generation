
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
), 
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COUNT(ci.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    GROUP BY ak.name, ak.person_id
), 
MoviesWithGenres AS (
    SELECT 
        mt.movie_id,
        mt.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mt.movie_id, mt.title
)
SELECT 
    rt.title,
    rt.production_year,
    ad.actor_name,
    ad.movie_count,
    mwg.keywords
FROM RankedTitles rt
JOIN ActorDetails ad ON ad.movie_count > 1
LEFT JOIN complete_cast cc ON cc.movie_id = rt.title_id
JOIN MoviesWithGenres mwg ON mwg.movie_id = cc.movie_id
WHERE rt.title_rank <= 5
  AND (ad.actor_rank = 1 OR ad.actor_rank IS NULL)
ORDER BY rt.production_year DESC, ad.movie_count DESC;
