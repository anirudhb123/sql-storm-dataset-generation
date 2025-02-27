
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 3
),
MovieDetails AS (
    SELECT 
        hm.movie_id,
        hm.title,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        HighRankedMovies hm
    LEFT JOIN 
        complete_cast cc ON hm.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name a ON cc.subject_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON hm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON hm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        hm.movie_id, hm.title
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.actors,
        md.companies,
        md.keyword_count,
        COALESCE(md.keyword_count, 0) AS non_null_keywords
    FROM 
        MovieDetails md
)
SELECT 
    f.movie_id,
    f.title,
    f.actors,
    f.companies,
    f.non_null_keywords,
    CASE 
        WHEN f.non_null_keywords > 10 THEN 'High'
        WHEN f.non_null_keywords BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low' 
    END AS keyword_rating
FROM 
    FinalOutput f
ORDER BY 
    f.movie_id DESC, 
    f.non_null_keywords DESC;
