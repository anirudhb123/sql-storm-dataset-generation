WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ac.name AS company_name,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT na.name, ', ') AS cast_names
    FROM 
        RankedTitles rt
    JOIN 
        aka_title m ON rt.title_id = m.id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name ac ON mc.company_id = ac.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name na ON ci.person_id = na.person_id
    WHERE 
        rt.rank <= 5 -- Top 5 titles per production year by keyword count
    GROUP BY 
        m.id, m.title, m.production_year, ac.name, ct.kind
),
FinalResults AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_name,
        md.company_type,
        md.cast_names,
        COUNT(DISTINCT na.id) AS unique_names_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        aka_name na ON md.title = na.name
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.company_name, md.company_type, md.cast_names
)

SELECT 
    *,
    TRIM(BOTH ',' FROM REPLACE(cast_names, ', ,', ',')) AS cleaned_cast_names
FROM 
    FinalResults
ORDER BY 
    production_year DESC, unique_names_count DESC;
