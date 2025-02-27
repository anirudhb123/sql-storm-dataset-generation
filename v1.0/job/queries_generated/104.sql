WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM
        title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
HighestRankedMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank = 1
),
MovieDetails AS (
    SELECT 
        hm.title_id,
        hm.title,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        HighestRankedMovies hm
    LEFT JOIN 
        movie_companies mc ON hm.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON hm.title_id = mk.movie_id
    GROUP BY 
        hm.title_id, hm.title
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_names, 'No companies') AS companies,
    md.keyword_count
FROM 
    MovieDetails md 
LEFT JOIN 
    aka_title ak ON ak.movie_id = md.title_id 
WHERE 
    (md.keyword_count > 0 OR ak.title IS NOT NULL)
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
