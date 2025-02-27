WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak 
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 0
),
PopularGenres AS (
    SELECT 
        mt.movie_id,
        kt.keyword AS genre_keyword
    FROM 
        movie_keyword mk 
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        movie_info m ON mk.movie_id = m.movie_id
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'genre') 
    GROUP BY 
        mt.movie_id, kt.keyword
),
CompanyInformation AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    pg.genre_keyword,
    ci.company_name,
    ci.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularGenres pg ON rm.movie_id = pg.movie_id
LEFT JOIN 
    CompanyInformation ci ON rm.movie_id = ci.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
