WITH MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.kind_id,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.title, mt.production_year, mt.kind_id
),
TopGenres AS (
    SELECT 
        kt.kind AS genre,
        COUNT(DISTINCT md.title) AS movie_count
    FROM 
        MovieDetails md
    INNER JOIN 
        kind_type kt ON md.kind_id = kt.id
    GROUP BY 
        kt.kind
    HAVING 
        COUNT(DISTINCT md.title) > 5
),
GenreRank AS (
    SELECT 
        genre,
        RANK() OVER (ORDER BY movie_count DESC) AS genre_rank
    FROM 
        TopGenres
)

SELECT 
    g.genre,
    g.movie_count,
    md.title,
    md.production_year,
    md.actors
FROM 
    GenreRank g
JOIN 
    MovieDetails md ON g.genre = (SELECT kt.kind FROM kind_type kt WHERE kt.id = md.kind_id)
WHERE 
    g.genre_rank <= 3
ORDER BY 
    g.movie_count DESC,
    md.production_year DESC;
