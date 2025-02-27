WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
MovieData AS (
    SELECT 
        mt.movie_id,
        GROUP_CONCAT(DISTINCT c.name) AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        mc.note IS NULL
    GROUP BY 
        mt.movie_id
),
GenreData AS (
    SELECT 
        kt.id AS keyword_id,
        kt.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        keyword kt
    LEFT JOIN 
        movie_keyword mk ON kt.id = mk.keyword_id
    GROUP BY 
        kt.id
    HAVING 
        COUNT(mk.movie_id) > 1
),
FinalResults AS (
    SELECT 
        rt.title,
        rt.production_year,
        md.company_names,
        md.keywords,
        md.cast_count,
        gd.keyword_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MovieData md ON rt.title_id = md.movie_id
    LEFT JOIN 
        GenreData gd ON md.keywords LIKE '%' || gd.keyword || '%'
    WHERE 
        rt.title_rank = 1
        AND (md.cast_count IS NULL OR md.cast_count > 5)
)

SELECT 
    fr.title,
    fr.production_year,
    fr.company_names,
    fr.keywords,
    fr.cast_count,
    fr.keyword_count
FROM 
    FinalResults fr
WHERE 
    fr.production_year NOT IN (SELECT DISTINCT production_year FROM RankedTitles WHERE title_rank > 5)
ORDER BY 
    fr.production_year DESC, fr.title;
