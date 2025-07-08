
WITH RECURSIVE PopularTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS cast_rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
FeaturedCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
TopRankedActors AS (
    SELECT 
        a.name,
        COUNT(DISTINCT c.movie_id) AS movies_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) >= 3
)
SELECT 
    pt.title,
    pt.total_cast,
    COALESCE(fc.companies, 'No companies listed') AS companies,
    tra.name AS top_actor,
    tra.movies_count
FROM 
    PopularTitles pt
LEFT JOIN 
    FeaturedCompanies fc ON pt.title_id = fc.movie_id
LEFT JOIN 
    (SELECT 
         name, movies_count 
     FROM 
         TopRankedActors 
     WHERE 
         rank = 1) tra ON pt.title_id IN (
         SELECT movie_id 
         FROM cast_info ci 
         JOIN aka_name an ON ci.person_id = an.person_id 
         WHERE an.name = tra.name
     )
WHERE 
    pt.cast_rank < 10
ORDER BY 
    pt.total_cast DESC, 
    pt.title;
