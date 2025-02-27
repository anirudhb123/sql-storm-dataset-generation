
WITH MovieStats AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(MIN(ci.nr_order), 0) AS min_cast_order,
        COUNT(DISTINCT mci.company_id) AS production_companies,
        AVG(CASE WHEN ti.info LIKE '%Oscar%' THEN 1 ELSE 0 END) AS has_oscar_award
    FROM aka_title mt
    LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN movie_companies mci ON mt.id = mci.movie_id
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN movie_info_idx ti ON mi.id = ti.movie_id
    GROUP BY mt.id, mt.title
),
TopMovies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.min_cast_order,
        ms.production_companies,
        ms.has_oscar_award,
        ROW_NUMBER() OVER (ORDER BY ms.production_companies DESC, ms.has_oscar_award DESC) AS rank
    FROM MovieStats ms
    WHERE ms.production_companies > 2
)
SELECT 
    tm.title,
    tm.min_cast_order,
    tm.production_companies,
    CASE 
        WHEN tm.has_oscar_award > 0 THEN 'Yes'
        ELSE 'No'
    END AS won_oscar
FROM TopMovies tm
WHERE tm.rank <= 10
ORDER BY tm.rank;
