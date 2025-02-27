WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rn
    FROM 
        title t 
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        AVG(mi.info_length) AS avg_info_length
    FROM 
        complete_cast m
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id 
    LEFT JOIN (
        SELECT 
            movie_id,
            LENGTH(info) AS info_length
        FROM 
            movie_info
        WHERE 
            info IS NOT NULL
    ) mi ON m.movie_id = mi.movie_id 
    GROUP BY 
        m.movie_id
),
CompanyContribution AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        rt.production_year,
        rt.title,
        md.total_cast,
        md.cast_names,
        cc.total_companies,
        CASE 
            WHEN md.avg_info_length IS NULL THEN 'No Info'
            ELSE CAST(md.avg_info_length AS TEXT)
        END AS avg_length_info
    FROM 
        RankedTitles rt
    JOIN 
        MovieDetails md ON rt.title_id = md.movie_id
    LEFT JOIN 
        CompanyContribution cc ON md.movie_id = cc.movie_id
    WHERE 
        rt.rn <= 5 AND rt.production_year >= 2000
)
SELECT 
    production_year,
    title,
    total_cast,
    cast_names,
    total_companies,
    avg_length_info
FROM 
    FinalResults
ORDER BY 
    production_year DESC, total_cast DESC;
