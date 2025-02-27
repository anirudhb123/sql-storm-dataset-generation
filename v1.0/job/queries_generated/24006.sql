WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.id = t.id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),
FilteredMovies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.movie_id ORDER BY mt.production_year DESC) AS keyword_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        MoviesWithKeywords mk ON mt.movie_id = mk.movie_id
    WHERE 
        mt.production_year > 2000
)
SELECT 
    rt.aka_id,
    rt.aka_name,
    fm.title,
    fm.production_year,
    fm.keywords,
    IFNULL((SELECT COUNT(*) FROM cast_info c WHERE c.movie_id = fm.movie_id AND c.note IS NULL), 0) AS uncredited_cast_count,
    (SELECT COUNT(DISTINCT mc.company_id) 
     FROM movie_companies mc 
     WHERE mc.movie_id = fm.movie_id 
       AND mc.note IS NOT NULL) AS unique_company_count,
    DENSE_RANK() OVER (ORDER BY fm.production_year DESC) AS year_rank
FROM 
    RankedTitles rt
JOIN 
    FilteredMovies fm ON rt.title_id = fm.movie_id
WHERE 
    rt.rank_year <= 5
    AND (EXISTS (SELECT 1 
                  FROM movie_info mi 
                  WHERE mi.movie_id = fm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info LIKE '%rating%')))
         OR rt.aka_name LIKE '%star%')
ORDER BY 
    rt.aka_name ASC, 
    fm.production_year DESC
LIMIT 100;
