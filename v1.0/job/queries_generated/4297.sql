WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(cc.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info cc ON a.id = cc.movie_id
    WHERE
        a.production_year IS NOT NULL
    GROUP BY
        a.title, a.production_year
),
FilteredMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.cast_count,
        CASE 
            WHEN rm.cast_count = 0 THEN 'No cast'
            WHEN rm.cast_count < 5 THEN 'Limited cast'
            ELSE 'Large cast'
        END AS cast_size
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 10
)
SELECT
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.cast_size,
    (SELECT COUNT(DISTINCT mc.company_id) 
     FROM movie_companies mc 
     JOIN company_name cn ON mc.company_id = cn.imdb_id 
     WHERE mc.movie_id = (SELECT mt.id FROM aka_title mt WHERE mt.title = fm.title LIMIT 1)) AS company_count,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM movie_companies mc 
     JOIN company_name cn ON mc.company_id = cn.imdb_id 
     WHERE mc.movie_id = (SELECT mt.id FROM aka_title mt WHERE mt.title = fm.title LIMIT 1)) AS company_names
FROM
    FilteredMovies fm
ORDER BY
    fm.production_year DESC,
    fm.cast_count DESC;
