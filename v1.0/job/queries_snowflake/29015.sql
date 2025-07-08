
WITH RankedNames AS (
    SELECT 
        an.id AS aka_id, 
        an.name AS aka_name,
        p.id AS person_id,
        p.name AS person_name,
        ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY LENGTH(an.name) DESC) AS name_rank
    FROM 
        aka_name an
    JOIN 
        name p ON an.person_id = p.id
    WHERE 
        an.name IS NOT NULL
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        COALESCE(m.keywords, 'No Keywords') AS keywords,
        COALESCE(m.companies, 'No Companies') AS companies
    FROM 
        MovieInfo m
    WHERE 
        m.production_year >= 2000
    ORDER BY 
        m.production_year DESC
    LIMIT 10
)

SELECT 
    tn.aka_name,
    tn.person_name,
    tm.movie_title,
    tm.production_year,
    tm.keywords,
    tm.companies
FROM 
    RankedNames tn
JOIN 
    TopMovies tm ON tn.person_id IN (
        SELECT ci.person_id
        FROM cast_info ci
        WHERE ci.movie_id = tm.movie_id
    )
WHERE 
    tn.name_rank = 1
ORDER BY 
    tm.production_year DESC, tn.aka_name;
