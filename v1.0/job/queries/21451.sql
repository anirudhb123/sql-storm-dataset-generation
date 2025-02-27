
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS total_cast_with_notes
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast AS cc ON mc.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mc.movie_id
),
ComplexSubquery AS (
    SELECT 
        t.title,
        CASE 
            WHEN COUNT(DISTINCT ci.person_id) = 0 THEN 'Unknown Cast'
            ELSE STRING_AGG(DISTINCT ak.name, ', ')
        END AS cast_names
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.title
    HAVING 
        COUNT(DISTINCT ci.person_id) < 5
),
MovieRanking AS (
    SELECT 
        title_id,
        title,
        production_year,
        title_rank,
        LAG(title_rank) OVER (ORDER BY production_year) AS prev_title_rank,
        LEAD(title_rank) OVER (ORDER BY production_year) AS next_title_rank
    FROM 
        RankedTitles
)
SELECT 
    mt.title,
    mt.production_year,
    COALESCE(fc.company_names, 'No Companies') AS company_names,
    COALESCE(cs.cast_names, 'No Cast') AS cast_information,
    CASE 
        WHEN mt.title_rank IS NULL THEN 'Ranking Unavailable'
        ELSE CAST(mt.title_rank AS VARCHAR)
    END AS title_ranking,
    CASE 
        WHEN mt.title_rank IS NOT NULL AND (mt.title_rank - mt.prev_title_rank) > 1 THEN 'Notable Drop'
        WHEN mt.title_rank IS NOT NULL AND (mt.title_rank - mt.next_title_rank) < -1 THEN 'Notable Surge'
        ELSE 'Stable Rank'
    END AS rank_trend
FROM 
    MovieRanking AS mt
LEFT JOIN 
    FilteredMovies AS fc ON mt.title_id = fc.movie_id
LEFT JOIN 
    ComplexSubquery AS cs ON mt.title = cs.title
WHERE 
    mt.title IS NOT NULL
ORDER BY 
    mt.production_year DESC, mt.title;
