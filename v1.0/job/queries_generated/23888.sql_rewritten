WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.id) DESC) AS rank_by_cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_count <= 3
),
MovieActors AS (
    SELECT 
        km.movie_id,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index,
        ct.kind AS char_type,
        ROW_NUMBER() OVER (PARTITION BY km.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        movie_keyword mk
    JOIN 
        aka_name ak ON ak.id = mk.keyword_id  
    JOIN 
        aka_title mt ON mt.id = mk.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    JOIN 
        complete_cast km ON km.movie_id = mt.id
    WHERE 
        ak.name IS NOT NULL AND ak.name <> ''
),
FinalSelection AS (
    SELECT 
        t.title,
        t.production_year,
        ma.actor_name,
        ma.actor_imdb_index,
        COUNT(ma.actor_name) OVER (PARTITION BY t.movie_id) AS total_actors,
        STRING_AGG(ma.actor_name, ', ') AS actors_list
    FROM 
        TopMovies t
    LEFT JOIN 
        MovieActors ma ON t.movie_id = ma.movie_id
    GROUP BY 
        t.movie_id, t.title, t.production_year, ma.actor_name, ma.actor_imdb_index
)
SELECT 
    fs.title,
    fs.production_year,
    fs.actors_list,
    CASE 
        WHEN fs.total_actors IS NULL THEN 'No actors found'
        ELSE CONCAT('Total actors: ', fs.total_actors)
    END AS actor_summary
FROM 
    FinalSelection fs
WHERE 
    fs.production_year >= 1990
ORDER BY 
    fs.production_year DESC, 
    fs.title ASC;