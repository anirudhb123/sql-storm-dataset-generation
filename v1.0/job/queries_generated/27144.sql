WITH RecursiveMovieData AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        c.name AS company_name, 
        c.country_code,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT ak.name) AS aliases,
        GROUP_CONCAT(DISTINCT p.info) AS person_infos
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
    GROUP BY 
        m.id, c.country_code, c.name
),
RankedMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        kind_id,
        company_name,
        country_code,
        keywords,
        aliases,
        person_infos,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(aliases) DESC) AS rank
    FROM 
        RecursiveMovieData
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.kind_id,
    rm.company_name,
    rm.country_code,
    rm.keywords,
    rm.aliases,
    rm.person_infos
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.rank;
