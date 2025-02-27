WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COALESCE(SUM(mi.info_type_id), 0) AS total_info_types
    FROM aka_title mt
    LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    WHERE mt.production_year >= 2000
    GROUP BY mt.id
),
RankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_names,
        total_info_types,
        RANK() OVER (ORDER BY total_cast DESC, production_year DESC) AS rank_by_cast,
        DENSE_RANK() OVER (ORDER BY total_info_types DESC) AS rank_by_info
    FROM MovieDetails
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.cast_names,
    rm.total_info_types,
    CASE 
        WHEN rm.rank_by_cast = 1 THEN 'Top cast movie'
        ELSE 'Regular movie'
    END AS cast_rating,
    CASE 
        WHEN rm.rank_by_info = 1 THEN 'Info-rich movie'
        ELSE 'Info-scarce movie'
    END AS info_rating
FROM RankedMovies rm
WHERE rm.total_cast > 5
ORDER BY rm.rank_by_cast, rm.production_year DESC;
