
WITH RecursiveTitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
), 

ActorSummary AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movie_titles
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        RecursiveTitleInfo AS t ON c.movie_id = t.title_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
), 

CompanyGroup AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(DISTINCT mc.company_id) > 2
)

SELECT 
    t.id AS movie_id,
    t.title,
    t.production_year,
    COALESCE(asum.total_movies, 0) AS actor_count,
    asum.movie_titles,
    COALESCE(cg.company_names, 'No Companies') AS company_names,
    cg.num_companies,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = t.id) AS complete_cast_count,
    (SELECT AVG(CAST(pi.info AS FLOAT)) 
     FROM person_info pi 
     WHERE pi.info_type_id = (
         SELECT id FROM info_type WHERE info = 'Rating' LIMIT 1
     ) 
     AND pi.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = t.id)) AS avg_rating
FROM 
    aka_title AS t
LEFT JOIN 
    ActorSummary AS asum ON asum.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = t.id)
LEFT JOIN 
    CompanyGroup AS cg ON cg.movie_id = t.id
WHERE 
    t.production_year >= 2000
    AND (t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%') OR t.kind_id IS NULL)
ORDER BY 
    t.production_year DESC, 
    t.title ASC
LIMIT 50;
