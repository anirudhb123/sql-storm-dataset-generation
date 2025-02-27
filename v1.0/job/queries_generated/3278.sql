WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.*, 
        COALESCE(MAX(mk.keyword), 'No Keywords') AS keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = rm.movie_id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
PersonDetails AS (
    SELECT 
        p.id AS person_id, 
        ak.name AS person_name,
        pi.info AS person_info
    FROM 
        aka_name ak
    JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.keyword,
    pd.person_name,
    pd.person_info
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info ci ON ci.movie_id = fm.movie_id
LEFT JOIN 
    PersonDetails pd ON pd.person_id = ci.person_id
WHERE 
    fm.keyword IS NOT NULL
ORDER BY 
    fm.production_year DESC, fm.title;
