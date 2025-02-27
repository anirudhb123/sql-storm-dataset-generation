WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    GROUP BY m.id, m.title, m.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.cast_count
    FROM RankedMovies rm
    WHERE rm.production_year BETWEEN 2000 AND 2023
    AND rm.cast_count > 5
)
SELECT 
    f.title,
    f.production_year,
    f.keyword,
    p.name AS lead_actor,
    COUNT(mk.id) AS keyword_count
FROM FilteredMovies f
JOIN complete_cast cc ON f.movie_id = cc.movie_id
JOIN cast_info c ON cc.subject_id = c.id
JOIN aka_name p ON c.person_id = p.person_id AND p.md5sum = (
    SELECT MIN(md5sum)
    FROM aka_name
    WHERE person_id = p.person_id
)
JOIN movie_keyword mk ON f.movie_id = mk.movie_id
GROUP BY f.title, f.production_year, f.keyword, p.name
ORDER BY f.production_year DESC, f.keyword;