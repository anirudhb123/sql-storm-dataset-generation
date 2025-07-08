
WITH MovieYearCTE AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
), 
CompanyStats AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type, 
        COUNT(mc.id) AS num_movies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
), 
KeywordStats AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
), 
RankedMovies AS (
    SELECT 
        my.movie_id, 
        my.title, 
        my.production_year, 
        my.num_cast_members,
        COALESCE(cs.num_movies, 0) AS num_production_companies,
        COALESCE(ks.keywords, 'None') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY my.production_year ORDER BY my.num_cast_members DESC) AS rank
    FROM MovieYearCTE my
    LEFT JOIN CompanyStats cs ON my.movie_id = cs.movie_id
    LEFT JOIN KeywordStats ks ON my.movie_id = ks.movie_id
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.num_cast_members, 
    rm.num_production_companies,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top Movie of Year'
        ELSE 'Regular Movie'
    END AS movie_category,
    rm.keywords
FROM RankedMovies rm
WHERE rm.production_year BETWEEN 2000 AND 2020
ORDER BY rm.production_year, rm.num_cast_members DESC;
