WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        title AS t
    WHERE 
        t.production_year IS NOT NULL
),

MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_companies AS mt
    LEFT JOIN 
        company_name AS cn ON mt.company_id = cn.id
    LEFT JOIN 
        company_type AS ct ON mt.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword AS mk ON mt.movie_id = mk.movie_id
    GROUP BY 
        mt.movie_id, mt.company_id, cn.name, ct.kind
),

CastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ci.movie_id
),

FinalBenchmark AS (
    SELECT 
        rt.title,
        rt.production_year,
        md.company_name,
        md.company_type,
        ci.total_cast,
        ci.actor_names,
        md.keyword_count,
        CASE 
            WHEN md.keyword_count > 0 THEN 'Has Keywords'
            ELSE 'No Keywords'
        END AS keyword_status
    FROM 
        RankedTitles AS rt
    LEFT JOIN 
        MovieDetails AS md ON rt.title_id = md.movie_id
    LEFT JOIN 
        CastInfo AS ci ON md.movie_id = ci.movie_id
)

SELECT 
    f.title,
    f.production_year,
    f.company_name,
    f.company_type,
    f.total_cast,
    f.actor_names,
    f.keyword_count,
    f.keyword_status
FROM 
    FinalBenchmark AS f
WHERE 
    f.production_year BETWEEN 2000 AND 2020
ORDER BY 
    f.production_year DESC,
    f.keyword_count DESC NULLS LAST,
    f.title ASC;
