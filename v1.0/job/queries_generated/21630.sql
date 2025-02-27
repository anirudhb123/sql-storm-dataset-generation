WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season_number,
        COALESCE(mt.episode_nr, 0) AS episode_number,
        ka.name AS person_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY coalesce(ca.nr_order, 999) ASC) AS cast_order,
        CASE 
            WHEN a.kind_id IS NULL THEN 'Unknown'
            ELSE kt.kind
        END AS movie_kind,
        COUNT(DISTINCT kc.keyword) AS num_keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ca ON mt.id = ca.movie_id
    LEFT JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    LEFT JOIN 
        kind_type kt ON mt.kind_id = kt.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        mt.production_year IS NOT NULL
        AND (mt.note IS NULL OR mt.note <> 'deleted')
    GROUP BY 
        mt.id, mt.title, mt.production_year, kt.kind, ka.name, ca.nr_order
), 
TopMovies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY md.movie_kind ORDER BY md.production_year DESC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.season_number,
    tm.episode_number,
    tm.person_name,
    tm.cast_order,
    tm.movie_kind,
    tm.num_keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 5
    OR (tm.rank IS NULL AND tm.movie_kind = 'Unknown')
ORDER BY 
    tm.movie_kind ASC, 
    tm.production_year DESC, 
    tm.cast_order ASC;
