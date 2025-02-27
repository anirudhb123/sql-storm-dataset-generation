WITH RankedCast AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(STRING_AGG(DISTINCT ak.actor_name, ', '), 'No Cast') AS cast_list,
        COALESCE(STRING_AGG(DISTINCT mk.keyword, ', '), 'No Keywords') AS keywords,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'No Companies') AS production_companies
    FROM 
        title t
    LEFT JOIN 
        RankedCast rc ON t.id = rc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_list,
        md.keywords,
        md.production_companies,
        CASE 
            WHEN md.production_year < 2000 THEN 'Classic'
            WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        MovieDetails md
)

SELECT 
    era,
    COUNT(*) AS movie_count,
    STRING_AGG(title, '; ') AS titles,
    STRING_AGG(cast_list, '; ') AS all_casts
FROM 
    FinalOutput
GROUP BY 
    era
ORDER BY 
    era;
