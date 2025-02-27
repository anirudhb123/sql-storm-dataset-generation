WITH MovieAwards AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COUNT(aw.award_id) AS total_awards
    FROM aka_title mt
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN movie_info_idx mii ON mi.id = mii.movie_info_id
    LEFT JOIN (
        SELECT movie_id, COUNT(id) as award_id
        FROM movie_info
        WHERE info_type_id IN (SELECT id FROM info_type WHERE info = 'Award')
        GROUP BY movie_id
    ) aw ON mt.id = aw.movie_id
    GROUP BY mt.id, mt.title
),
PopularActors AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    WHERE ci.nr_order IS NOT NULL
    GROUP BY ka.person_id, ka.name
    HAVING COUNT(DISTINCT ci.movie_id) > 5
),
TopMovieActors AS (
    SELECT 
        ma.movie_id,
        ma.title, 
        ROW_NUMBER() OVER (PARTITION BY ma.movie_id ORDER BY pa.movie_count DESC) AS actor_rank
    FROM MovieAwards ma
    JOIN PopularActors pa ON pa.movie_count > 5
    WHERE ma.total_awards > 0
)

SELECT 
    ma.title,
    pa.name,
    ma.total_awards,
    pa.movie_count
FROM TopMovieActors tma
JOIN MovieAwards ma ON ma.movie_id = tma.movie_id
JOIN PopularActors pa ON pa.person_id IN (
    SELECT ci.person_id 
    FROM cast_info ci 
    WHERE ci.movie_id = tma.movie_id
    ORDER BY ci.nr_order
)
ORDER BY ma.total_awards DESC, pa.movie_count DESC
LIMIT 10;
