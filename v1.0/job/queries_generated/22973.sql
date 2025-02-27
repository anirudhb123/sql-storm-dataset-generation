WITH actor_movie_counts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
), 
movie_title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
),
keyword_aggregates AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
final_output AS (
    SELECT 
        mti.title,
        mti.production_year,
        mti.kind,
        ka.person_id,
        ac.movie_count,
        ka.name,
        ka.name_pcode_cf,
        ka.name_pcode_nf,
        COALESCE(cmp.companies, 'No Companies') AS companies,
        COALESCE(kag.all_keywords, 'No Keywords') AS keywords,
        RANK() OVER (PARTITION BY mti.production_year ORDER BY mti.production_year DESC) AS production_rank
    FROM 
        movie_title_info mti
    LEFT JOIN 
        cast_info ci ON mti.title_id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        actor_movie_counts ac ON ka.person_id = ac.person_id
    LEFT JOIN 
        keyword_aggregates kag ON mti.title_id = kag.movie_id
    LEFT JOIN 
        company_details cmp ON mti.title_id = cmp.movie_id
    WHERE 
        mti.year_rank <= 5 AND 
        (ACOS(NULLIF(SIN(0), 10)) IS NULL OR ka.name IS NOT NULL) AND
        ka.name_pcode_cf IS DISTINCT FROM ka.name_pcode_nf
)
SELECT 
    title,
    production_year,
    kind,
    person_id,
    movie_count,
    name,
    companies,
    keywords,
    production_rank
FROM 
    final_output
WHERE 
    production_year IN (SELECT DISTINCT production_year FROM final_output WHERE companies <> 'No Companies')
ORDER BY 
    production_year DESC, 
    title;
