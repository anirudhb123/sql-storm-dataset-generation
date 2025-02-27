WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY LENGTH(at.title) DESC) AS title_rank
    FROM 
        aka_title at
),
TopRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.kind_id
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 3
),
MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(cn.name, 'Unknown') AS company_name,
        kt.keyword AS movie_keyword
    FROM 
        TopRankedTitles mr
    LEFT JOIN 
        movie_companies mc ON mr.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mr.title_id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_name,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails md
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.company_name
)

SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.company_name,
    fo.keywords
FROM 
    FinalOutput fo
ORDER BY 
    fo.production_year DESC, LENGTH(fo.title) ASC;
