
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rn,
        COUNT(*) OVER (PARTITION BY title.production_year) AS total_movies
    FROM title
    WHERE title.production_year IS NOT NULL
),
NonDramaticMovies AS (
    SELECT m.movie_id, m.title, m.production_year
    FROM RankedMovies m
    LEFT JOIN aka_title a ON m.movie_id = a.movie_id
    LEFT JOIN kind_type k ON a.kind_id = k.id
    WHERE k.kind IS NULL OR k.kind <> 'Drama'
),
DirectorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS director_count
    FROM cast_info c
    INNER JOIN role_type r ON c.role_id = r.id
    WHERE r.role = 'Director'
    GROUP BY c.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        nm.title,
        nm.production_year,
        dc.director_count,
        COALESCE(SUM(CASE WHEN mi.info LIKE '%box office%' THEN 1 ELSE 0 END), 0) AS box_office_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM NonDramaticMovies nm
    LEFT JOIN DirectorCount dc ON nm.movie_id = dc.movie_id
    LEFT JOIN movie_info mi ON nm.movie_id = mi.movie_id
    LEFT JOIN movie_keyword mk ON nm.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY nm.title, nm.production_year, dc.director_count
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.director_count,
    dmi.box_office_count,
    dmi.keyword_count,
    CASE 
        WHEN dmi.director_count > 0 THEN 'Directed'
        ELSE 'Not Directed'
    END AS directed_status,
    CASE 
        WHEN dmi.keyword_count > 0 THEN 'Has Keywords'
        ELSE 'No Keywords'
    END AS keyword_status
FROM DetailedMovieInfo dmi
WHERE dmi.production_year >= 2000
  AND (dmi.box_office_count > 0 OR dmi.director_count IS NULL)
ORDER BY 
    dmi.production_year DESC, 
    dmi.title;
