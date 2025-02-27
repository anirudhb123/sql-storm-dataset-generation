WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.length DESC) AS rank
    FROM (
        SELECT 
            t.title,
            t.production_year,
            COUNT(c.id) AS length
        FROM title t
        LEFT JOIN complete_cast cc ON t.id = cc.movie_id
        LEFT JOIN cast_info c ON cc.subject_id = c.person_id
        GROUP BY t.id, t.title, t.production_year
    ) a
),
PopularActors AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    GROUP BY ak.name
    HAVING COUNT(DISTINCT c.movie_id) > 10
),
FilteredMovies AS (
    SELECT 
        r.title,
        r.production_year
    FROM RankedMovies r
    JOIN PopularActors pa ON r.rank <= 10 
    AND EXISTS (
        SELECT 1
        FROM cast_info c
        WHERE c.movie_id = r.id AND c.person_id IN (
            SELECT person_id FROM aka_name WHERE name LIKE 'John%'
        )
    )
)
SELECT 
    fm.title,
    fm.production_year,
    pa.name AS popular_actor,
    COALESCE(pg.info, 'No additional info') AS movie_detail
FROM FilteredMovies fm
LEFT JOIN movie_info_idx pg ON pg.movie_id = fm.id
JOIN PopularActors pa ON pa.movie_count > 5
ORDER BY fm.production_year DESC, fm.title;
