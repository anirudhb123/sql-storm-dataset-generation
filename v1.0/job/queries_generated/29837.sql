WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title a
    JOIN 
        cast_info c ON c.movie_id = a.id
    JOIN 
        aka_name an ON an.person_id = c.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id
),

MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.kind_id,
        rm.cast_count,
        rm.actor_names,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = rm.movie_id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rm.kind_id, rm.cast_count, rm.actor_names
),

MoviesRankedByActors AS (
    SELECT 
        mwk.movie_id,
        mwk.movie_title,
        mwk.production_year,
        mwk.cast_count,
        mwk.keywords,
        ROW_NUMBER() OVER (ORDER BY mwk.cast_count DESC) AS rank
    FROM 
        MoviesWithKeywords mwk
)

SELECT 
    mv.title AS Movie_Title,
    mv.production_year AS Production_Year,
    mv.cast_count AS Actor_Count,
    mv.keywords AS Movie_Keywords,
    mv.rank AS Actor_Rank
FROM 
    MoviesRankedByActors mv
WHERE 
    mv.rank <= 10
ORDER BY 
    mv.rank;
