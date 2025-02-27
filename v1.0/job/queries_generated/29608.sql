WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        ct.kind AS company_type,
        ARRAY_AGG(DISTINCT a.name) AS cast_members
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        t.id, t.title, t.production_year, k.keyword, c.name, ct.kind
),
HighProductionYearMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        movie_keyword,
        company_name,
        company_type,
        cast_members
    FROM
        MovieDetails
    WHERE
        production_year > 2000
),
KeywordCount AS (
    SELECT 
        movie_id,
        COUNT(movie_keyword) AS keyword_count 
    FROM 
        MovieDetails 
    GROUP BY 
        movie_id
)
SELECT
    h.movie_id,
    h.movie_title,
    h.production_year,
    h.company_name,
    h.company_type,
    h.cast_members,
    kc.keyword_count
FROM 
    HighProductionYearMovies h
LEFT JOIN 
    KeywordCount kc ON h.movie_id = kc.movie_id
ORDER BY 
    h.production_year DESC, 
    kc.keyword_count DESC,
    h.movie_title ASC;
