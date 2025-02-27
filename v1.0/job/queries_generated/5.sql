WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

FinalStats AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        ks.keyword_count,
        CASE 
            WHEN md.actor_count IS NULL THEN 0 
            ELSE md.actor_count 
        END AS actor_count_safe,
        CASE 
            WHEN ks.keyword_count IS NULL THEN 0 
            ELSE ks.keyword_count 
        END AS keyword_count_safe
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordStats ks ON md.movie_id = ks.movie_id
)

SELECT 
    fs.movie_id, 
    fs.title, 
    fs.production_year,
    fs.actor_count_safe,
    fs.keyword_count_safe,
    COALESCE(fs.actor_count_safe - fs.keyword_count_safe, 0) AS actor_keyword_diff
FROM 
    FinalStats fs
ORDER BY 
    fs.production_year DESC, 
    fs.actor_count_safe DESC;
