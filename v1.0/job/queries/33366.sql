WITH RECURSIVE MovieHierarchy AS (
    SELECT id, title, production_year, episode_of_id, season_nr, episode_nr
    FROM aka_title
    WHERE production_year >= 2000
    UNION ALL
    SELECT a.id, a.title, a.production_year, a.episode_of_id, a.season_nr, a.episode_nr
    FROM aka_title a
    JOIN MovieHierarchy mh ON a.episode_of_id = mh.id
),
RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS num_actors,
        DENSE_RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank_in_year
    FROM 
        MovieHierarchy mt
    LEFT JOIN 
        cast_info cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.num_actors
    FROM 
        RankedMovies tm
    WHERE 
        tm.rank_in_year <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.num_actors,
    ARRAY_AGG(DISTINCT ak.name) AS actor_names,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    aka_name ak ON ak.person_id = cc.subject_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
GROUP BY 
    tm.title, tm.production_year, tm.num_actors
ORDER BY 
    tm.production_year DESC, tm.num_actors DESC;
