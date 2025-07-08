
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COALESCE(mci.note, 'No Note') DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mci ON t.movie_id = mci.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.production_year > 2000
),
PersonDetails AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.id) AS movie_count,
        MAX(p.gender) AS gender
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        a.name IS NOT NULL 
        AND (p.gender = 'F' OR p.gender IS NULL)
    GROUP BY 
        a.person_id, a.name
),
CompaniesWithMovies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    pd.name AS actor_name,
    pd.movie_count,
    cw.movie_id,
    cw.company_names,
    mw.keywords,
    CASE 
        WHEN pd.gender = 'F' THEN 'Female'
        WHEN pd.gender = 'M' THEN 'Male'
        ELSE 'Unknown' 
    END AS gender_desc
FROM 
    RankedMovies rm
JOIN 
    PersonDetails pd ON pd.movie_count > 2
LEFT JOIN 
    CompaniesWithMovies cw ON rm.movie_id = cw.movie_id 
LEFT JOIN 
    MoviesWithKeywords mw ON rm.movie_id = mw.movie_id
WHERE 
    rm.rank = 1 
    AND (cw.company_names IS NOT NULL OR mw.keywords IS NOT NULL) 
ORDER BY 
    rm.production_year DESC, 
    pd.movie_count DESC;
