WITH RecursiveMovieTitles AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
), 
PopularActors AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    GROUP BY ka.person_id, ka.name
    HAVING COUNT(DISTINCT ci.movie_id) > 5
), 
MovieGenres AS (
    SELECT 
        DISTINCT m.id AS movie_id, 
        kt.kind AS genre
    FROM aka_title m
    JOIN kind_type kt ON m.kind_id = kt.id
), 
CombinedData AS (
    SELECT 
        DISTINCT mt.movie_id,
        mt.title,
        mt.production_year,
        p.name AS actor_name,
        mg.genre,
        ROW_NUMBER() OVER (PARTITION BY mt.movie_id ORDER BY p.name) AS actor_rank
    FROM RecursiveMovieTitles mt
    LEFT JOIN PopularActors p ON mt.movie_id = (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = p.person_id LIMIT 1)
    LEFT JOIN MovieGenres mg ON mt.movie_id = mg.movie_id
    WHERE mg.genre IS NOT NULL
)
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    ARRAY_AGG(DISTINCT cd.genre) AS genres,
    STRING_AGG(DISTINCT cd.actor_name, ', ') AS actors
FROM CombinedData cd
WHERE cd.actor_rank <= 3  -- Only interested in top 3 actors per movie
GROUP BY cd.movie_id, cd.title, cd.production_year
HAVING COUNT(DISTINCT cd.actor_name) > 1  -- Only movies with multiple actors
ORDER BY cd.production_year DESC, cd.movie_id
LIMIT 100;

-- Additional filtering and logic concerning NULL values and bizarre cases
WITH SelectedMovies AS (
    SELECT 
        *,
        CASE 
            WHEN genres IS NULL THEN '[Unknown Genre]' 
            ELSE genres 
        END AS final_genre
    FROM (
        SELECT 
            movie_id,
            TITLE,
            production_year,
            COALESCE(genres, ARRAY[NULL::TEXT]) AS genres
        FROM (
            SELECT 
                cd.movie_id,
                cd.title,
                cd.production_year,
                ARRAY_AGG(DISTINCT cd.genre) AS genres
            FROM CombinedData cd
            WHERE cd.actor_rank <= 3
            GROUP BY cd.movie_id, cd.title, cd.production_year
        ) AS grouped_data
    ) AS result
)
SELECT 
    * 
FROM SelectedMovies
WHERE final_genre != '[Unknown Genre]' 
  AND production_year > 2000 
  AND (final_genre IS NOT NULL OR final_genre <> '[Unknown Genre]')
ORDER BY production_year DESC;

