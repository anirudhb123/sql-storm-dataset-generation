WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        k.keyword AS genre,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
        AND k.keyword IS NOT NULL
),
HighestRankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        kind_id,
        genre
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),
MovieDetails AS (
    SELECT 
        hm.movie_title,
        hm.production_year,
        hm.kind_id,
        c.name AS company_name,
        ci.role AS cast_role,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        HighestRankedMovies hm
    LEFT JOIN 
        movie_companies mc ON hm.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON hm.id = ci.movie_id
    GROUP BY 
        hm.movie_title, hm.production_year, hm.kind_id, c.name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.kind_id,
    md.company_name,
    md.total_cast,
    STRING_AGG(DISTINCT md.cast_role, ', ') AS roles
FROM 
    MovieDetails md
GROUP BY 
    md.movie_title, md.production_year, md.kind_id, md.company_name
ORDER BY 
    md.production_year DESC,
    md.total_cast DESC;
