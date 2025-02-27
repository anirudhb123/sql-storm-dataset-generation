WITH RecursiveMovie AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           t.kind_id,
           COALESCE(c.company_count, 0) AS company_count
    FROM aka_title t
    LEFT JOIN (
        SELECT movie_id,
               COUNT(*) AS company_count
        FROM movie_companies
        GROUP BY movie_id
    ) c ON t.id = c.movie_id
    WHERE t.production_year >= 2000
),
DirectorInfo AS (
    SELECT DISTINCT ci.movie_id,
                    a.name AS director_name,
                    ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS director_order
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    WHERE r.role = 'director'
),
KeywordStats AS (
    SELECT mk.movie_id,
           STRING_AGG(k.keyword, ', ') AS keywords,
           COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieSummary AS (
    SELECT rm.movie_id,
           rm.title,
           rm.production_year,
           COALESCE(di.director_name, 'Unknown') AS director_name,
           COALESCE(ks.keywords, 'No Keywords') AS keywords,
           COALESCE(ks.keyword_count, 0) AS keyword_count,
           rm.company_count,
           RANK() OVER (ORDER BY rm.production_year DESC, rm.company_count DESC) AS rank
    FROM RecursiveMovie rm
    LEFT JOIN DirectorInfo di ON rm.movie_id = di.movie_id
    LEFT JOIN KeywordStats ks ON rm.movie_id = ks.movie_id
    WHERE rm.company_count > 2 
)
SELECT ms.movie_id,
       ms.title,
       ms.production_year,
       ms.director_name,
       ms.keywords,
       ms.keyword_count,
       ms.company_count
FROM MovieSummary ms
WHERE ms.rank <= 10
ORDER BY ms.production_year DESC, ms.company_count DESC;