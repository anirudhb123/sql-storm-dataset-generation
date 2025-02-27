WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COALESCE(AVG(ci.nr_order), 0) AS avg_cast_order
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.note IS NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

BizarreRanking AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.keywords,
        cd.companies_involved,
        md.total_cast,
        cd.total_companies,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.avg_cast_order DESC NULLS LAST) AS rank_in_year
    FROM 
        MovieDetails AS md
    LEFT JOIN 
        CompanyDetails AS cd ON md.production_year = cd.movie_id
    WHERE 
        md.total_cast > 0
        AND (cd.total_companies IS NULL OR cd.total_companies > 1)
)

SELECT 
    b.movie_title,
    b.production_year,
    b.keywords,
    b.companies_involved,
    b.total_cast,
    b.total_companies,
    b.rank_in_year,
    CASE 
        WHEN b.total_cast > 10 THEN 'Large Ensemble'
        WHEN b.total_cast BETWEEN 5 AND 10 THEN 'Moderate Ensemble'
        ELSE 'Small Cast'
    END AS cast_size_category,
    CASE 
        WHEN b.rank_in_year IS NULL THEN 'Unranked'
        WHEN b.rank_in_year <= 5 THEN 'Top 5'
        ELSE 'Below Top 5'
    END AS ranking_category
FROM 
    BizarreRanking AS b
WHERE 
    (b.production_year > 2000 AND b.total_cast > 0) 
    OR b.companies_involved IS NULL
ORDER BY 
    b.production_year DESC, 
    b.rank_in_year ASC NULLS LAST;

