
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        CASE 
            WHEN t.production_year < 2000 THEN 'Classic'
            WHEN t.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        rm.keywords,
        rm.era,
        ROW_NUMBER() OVER (PARTITION BY rm.era ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
)

SELECT 
    trm.movie_id,
    trm.title,
    trm.production_year,
    trm.cast_count,
    trm.cast_names,
    trm.keywords,
    trm.era
FROM 
    TopRatedMovies trm
WHERE 
    trm.rank <= 5
ORDER BY 
    trm.era, trm.cast_count DESC;
