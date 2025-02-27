WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank,
        COALESCE(k.keyword, 'Unknown') AS movie_keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
),
movie_stats AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        cd.total_cast,
        cd.cast_names,
        COALESCE(ci.companies, 'No Companies') AS companies,
        COALESCE(ci.company_type, 'N/A') AS company_type,
        CASE 
            WHEN rm.rank <= 5 THEN 'Top Ranked'
            ELSE 'Other Ranked'
        END AS ranking_category
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_details cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        company_info ci ON rm.movie_id = ci.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.cast_names,
    ms.companies,
    ms.company_type,
    ms.ranking_category
FROM 
    movie_stats ms
WHERE 
    ms.production_year IS NOT NULL
ORDER BY 
    ms.production_year DESC, ms.rank ASC
LIMIT 100;
