WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
MostPopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
FullMovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT km.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT rt.role) AS roles
    FROM 
        MostPopularMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        aka_name ak ON mc.company_id = ak.person_id  -- Assuming we want company names mapped to aka names
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        m.movie_id, m.title, m.production_year
)
SELECT 
    fmd.title,
    fmd.production_year,
    fmd.aka_names,
    fmd.keywords,
    fmd.roles
FROM 
    FullMovieDetails fmd
ORDER BY 
    fmd.production_year DESC;
