
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS valid_cast_count,
        AVG(t.production_year) OVER (PARTITION BY t.kind_id) AS avg_year_per_kind
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.id) > 5
), Companies AS (
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
), FinalReport AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        pk.keyword,
        COALESCE(c.company_name, 'Independent') AS company_name,
        COALESCE(c.company_type, 'N/A') AS company_type,
        md.valid_cast_count,
        md.avg_year_per_kind
    FROM 
        MovieDetails md
    LEFT JOIN 
        PopularKeywords pk ON md.movie_id = pk.movie_id
    LEFT JOIN 
        Companies c ON md.movie_id = c.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_count,
    keyword,
    company_name,
    company_type,
    valid_cast_count,
    avg_year_per_kind
FROM 
    FinalReport
WHERE 
    (production_year > 2000 AND actor_count > 10) OR 
    (company_type = 'Production' AND valid_cast_count > 5)
ORDER BY 
    production_year DESC, actor_count DESC;
