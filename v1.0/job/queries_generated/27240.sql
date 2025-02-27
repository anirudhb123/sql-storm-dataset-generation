WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMoviesWithGenres AS (
    SELECT 
        rm.title_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names,
        rm.keywords,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind) AS genres
    FROM 
        RankedMovies rm
    JOIN 
        kind_type ct ON rm.title_id = ct.id
    GROUP BY 
        rm.title_id, rm.movie_title, rm.production_year, rm.cast_count, rm.actor_names, rm.keywords
)
SELECT 
    r.title_id,
    r.movie_title,
    r.production_year,
    r.cast_count,
    r.actor_names,
    r.keywords,
    r.genres
FROM 
    RankedMoviesWithGenres r
ORDER BY 
    r.cast_count DESC, r.production_year ASC;
