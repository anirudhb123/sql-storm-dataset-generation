WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM aka_title at
    JOIN movie_keyword mk ON at.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword LIKE '%Action%'
),
ActorsInMovies AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        COUNT(ci.person_id) AS cast_count
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN aka_title at ON ci.movie_id = at.id
    GROUP BY ak.name, at.title
    HAVING COUNT(ci.person_id) > 1
),
FilteredResults AS (
    SELECT 
        r.title,
        r.production_year,
        COALESCE(a.actor_name, 'Unknown Actor') AS actor_name,
        a.cast_count
    FROM RankedMovies r
    LEFT JOIN ActorsInMovies a ON r.title = a.movie_title
    WHERE r.year_rank <= 5
)

SELECT 
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.cast_count,
    CASE 
        WHEN fr.cast_count IS NULL THEN 'No actors found'
        WHEN fr.cast_count > 5 THEN 'High Cast'
        ELSE 'Moderate Cast' 
    END AS cast_category
FROM FilteredResults fr
ORDER BY fr.production_year DESC, fr.title ASC;

