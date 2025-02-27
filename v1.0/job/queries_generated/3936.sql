WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighestRankedMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),
MovieDetails AS (
    SELECT
        hm.title,
        hm.production_year,
        STRING_AGG(cn.name, ', ') AS companies,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        HighestRankedMovies hm
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = hm.title AND production_year = hm.production_year LIMIT 1)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.imdb_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = hm.title AND production_year = hm.production_year LIMIT 1)
    GROUP BY 
        hm.title, hm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.companies, 'Unknown Company') AS companies,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 10 THEN 'Popular'
        WHEN md.keyword_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Niche'
    END AS popularity_category
FROM 
    MovieDetails md
WHERE 
    EXISTS (SELECT 1 FROM aka_name an WHERE an.person_id IN (SELECT ci.person_id FROM cast_info ci JOIN aka_title at ON ci.movie_id = at.id WHERE at.title = md.title))
ORDER BY 
    md.production_year DESC, md.title;
