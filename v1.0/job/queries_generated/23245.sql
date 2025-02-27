WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(ci.person_id) > 0
), 

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
), 

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
)

SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.cast_count,
    CASE 
        WHEN rm.cast_count >= 10 THEN 'Large Cast'
        WHEN rm.cast_count BETWEEN 5 AND 9 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    COALESCE(cd.company_name, 'Unknown Company') AS company_name,
    COALESCE(cd.company_type, 'Unknown Type') AS company_type
FROM 
    RankedMovies AS rm
LEFT JOIN 
    MovieKeywords AS mk ON rm.title = mk.movie_id
LEFT JOIN 
    CompanyDetails AS cd ON rm.title = cd.movie_id
WHERE 
    rm.rank <= 5
    AND (rm.production_year IS NOT NULL OR rm.production_year > 2000)
GROUP BY 
    rm.title, rm.production_year, rm.cast_count, cd.company_name, cd.company_type
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC
LIMIT 100
OFFSET 20;

-- Include any NULL checks or bizarre transformations if required (optional)
WITH FilteredTitles AS (
    SELECT 
        title, 
        production_year 
    FROM 
        aka_title 
    WHERE 
        NOT EXISTS (
            SELECT 1 
            FROM movie_info 
            WHERE movie_info.movie_id = aka_title.id AND 
                  movie_info.info_type_id = 1 AND info IS NULL
        )
)
SELECT *
FROM FilteredTitles
WHERE production_year < 2020 AND production_year > 1950;
