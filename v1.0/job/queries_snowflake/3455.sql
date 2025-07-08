
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
RecentMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 3
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    ci.company_name,
    ci.company_type,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = rm.production_year 
     AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_count,
    (SELECT LISTAGG(DISTINCT kw.keyword, ', ') 
     WITHIN GROUP (ORDER BY kw.keyword) 
     FROM movie_keyword mk 
     JOIN keyword kw ON mk.keyword_id = kw.id 
     WHERE mk.movie_id = rm.production_year) AS keywords
FROM 
    RecentMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
ORDER BY 
    rm.production_year DESC, rm.title ASC;
