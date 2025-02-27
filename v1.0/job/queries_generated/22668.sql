WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year,
        COUNT(mk.id) OVER (PARTITION BY t.id) AS keyword_count,
        COALESCE(MAX(k.keyword), 'No Keyword') AS main_keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
FilteredCompany AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    WHERE 
        ct.kind NOT LIKE '%Inc%' AND
        c.country_code IN ('USA', 'UK')
),
FinalResults AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.rank_year,
        ac.actor_count,
        fc.company_name,
        fc.company_type,
        rt.keyword_count,
        CASE 
            WHEN rt.keyword_count > 0 THEN 'Has Keywords'
            ELSE 'No Keywords'
        END AS keyword_status
    FROM 
        RankedTitles rt
    LEFT JOIN 
        ActorMovies ac ON rt.title_id = ac.movie_id
    LEFT JOIN 
        FilteredCompany fc ON rt.title_id = fc.movie_id
)
SELECT 
    title,
    production_year,
    rank_year,
    actor_count,
    company_name,
    company_type,
    keyword_count,
    keyword_status
FROM 
    FinalResults
WHERE 
    (rank_year <= 5 OR keyword_status = 'Has Keywords')
ORDER BY 
    production_year DESC, actor_count ASC NULLS LAST, title;
