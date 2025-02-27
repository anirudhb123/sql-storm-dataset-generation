WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
DirectorCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS director_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    WHERE 
        ct.kind = 'director'
    GROUP BY 
        mc.movie_id
),
FinalOutput AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(dc.director_count, 0) AS directors,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, rm.movie_rank) AS ranking
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DirectorCount dc ON rm.movie_id = dc.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.directors,
    CASE 
        WHEN f.directors = 0 THEN 'No Directors'
        WHEN f.directors > 5 THEN 'Many Directors'
        ELSE 'Few Directors'
    END AS director_description
FROM 
    FinalOutput f
WHERE 
    f.production_year >= 2000
ORDER BY 
    f.production_year DESC, f.ranking;
