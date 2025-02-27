WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) ASC) AS title_rank
    FROM 
        title t
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(mk.keyword_id), 0) AS keyword_count,
        COALESCE(COUNT(DISTINCT cc.person_id), 0) AS cast_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    GROUP BY 
        m.id
),
SelectedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.keyword_count,
        md.cast_count,
        rt.production_year
    FROM 
        MovieDetails md
    INNER JOIN 
        RankedTitles rt ON md.movie_id = rt.title_id
    WHERE 
        rt.title_rank <= 5
        AND md.keyword_count >= 3
)
SELECT 
    sm.title,
    sm.production_year,
    sm.keyword_count,
    sm.cast_count,
    (SELECT COUNT(*)
     FROM cast_info ci
     WHERE ci.movie_id = sm.movie_id AND ci.note IS NOT NULL) AS non_null_cast_info_count,
    (SELECT STRING_AGG(CONCAT_WS(' ', a.name, a.surname), ', ') 
     FROM aka_name a
     JOIN cast_info ci ON a.person_id = ci.person_id
     WHERE ci.movie_id = sm.movie_id) AS cast_names
FROM 
    SelectedMovies sm
WHERE 
    sm.cast_count > 5
ORDER BY 
    sm.production_year DESC,
    sm.keyword_count DESC;
